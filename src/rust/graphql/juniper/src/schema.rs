use chrono::Utc;
use deadpool_postgres::Pool;
use juniper::{EmptyMutation, EmptySubscription, RootNode};
use redis::aio::ConnectionManager;
use redis::AsyncCommands;

use crate::models::*;

pub struct Context {
    pub pool: Pool,
    pub redis: ConnectionManager,
}

impl juniper::Context for Context {}

pub struct QueryRoot;

#[juniper::graphql_object(Context = Context)]
impl QueryRoot {
    async fn health(ctx: &Context) -> Health {
        let db_status = match ctx.pool.get().await {
            Ok(conn) => match conn.query_one("SELECT 1", &[]).await {
                Ok(_) => "connected".to_string(),
                Err(_) => "error".to_string(),
            },
            Err(_) => "disconnected".to_string(),
        };

        let cache_status = {
            let mut conn = ctx.redis.clone();
            match redis::cmd("PING")
                .query_async::<String>(&mut conn)
                .await
            {
                Ok(_) => "connected".to_string(),
                Err(_) => "disconnected".to_string(),
            }
        };

        Health {
            status: "ok".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            timestamp: Utc::now().to_rfc3339(),
            database: db_status,
            cache: cache_status,
        }
    }

    async fn json_items(limit: Option<i32>) -> JsonItemsResult {
        let count = crate::canonical::item_count(limit.unwrap_or(0));
        // The previous version minted a Uuid::new_v4() per item -- 1000 random
        // UUIDs per request -- and formatted Utc::now() into every created_at.
        // See contracts/rest/canonical-payloads.md.
        let items: Vec<JsonItem> = (0..count)
            .map(|i| JsonItem {
                id: i,
                uuid: crate::canonical::uuid(i),
                name: crate::canonical::name(i),
                email: crate::canonical::email(i),
                created_at: crate::canonical::CANONICAL_CREATED_AT.to_string(),
                is_active: crate::canonical::is_active(i),
            })
            .collect();

        JsonItemsResult {
            count: items.len() as i32,
            items,
            timestamp: Utc::now().to_rfc3339(),
        }
    }

    async fn user(ctx: &Context, id: i32) -> Option<User> {
        let conn = ctx.pool.get().await.ok()?;

        let row = conn
            .query_opt(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
                &[&id],
            )
            .await
            .ok()?;

        row.map(|r| User {
            id: r.get(0),
            email: r.get(1),
            first_name: r.get(2),
            last_name: r.get(3),
            age: r.get(4),
            created_at: {
                let ts: chrono::NaiveDateTime = r.get(5);
                chrono::DateTime::<Utc>::from_naive_utc_and_offset(ts, Utc).to_rfc3339()
            },
        })
    }

    async fn complex_orders(ctx: &Context, days: Option<i32>) -> ComplexOrdersResult {
        let period_days = days.unwrap_or(30);
        let conn = ctx.pool.get().await.unwrap();

        let rows = conn
            .query(
                "SELECT
                    u.id AS user_id,
                    u.first_name || ' ' || u.last_name AS user_name,
                    COUNT(o.id) AS total_orders,
                    COALESCE(SUM(o.amount), 0) AS total_value,
                    COALESCE(AVG(o.amount), 0) AS average_order_value
                 FROM users u
                 LEFT JOIN orders o ON o.user_id = u.id
                    AND o.created_at >= NOW() - ($1 || ' days')::interval
                 GROUP BY u.id, u.first_name, u.last_name
                 ORDER BY total_value DESC",
                &[&period_days],
            )
            .await
            .unwrap();

        let data: Vec<UserOrderStats> = rows
            .iter()
            .map(|r| UserOrderStats {
                user_id: r.get(0),
                user_name: r.get(1),
                total_orders: r.get(2),
                total_value: {
                    let v: rust_decimal::Decimal = r.get(3);
                    v.to_string().parse::<f64>().unwrap_or(0.0)
                },
                average_order_value: {
                    let v: rust_decimal::Decimal = r.get(4);
                    v.to_string().parse::<f64>().unwrap_or(0.0)
                },
            })
            .collect();

        ComplexOrdersResult {
            period_days,
            total_users: data.len() as i32,
            data,
        }
    }

    async fn cache(ctx: &Context, key: String) -> CacheEntry {
        let mut conn = ctx.redis.clone();

        let cached: Option<String> = conn.get(&key).await.unwrap_or(None);

        if let Some(value) = cached {
            let ttl: i32 = conn.ttl(&key).await.unwrap_or(0);
            return CacheEntry {
                key,
                value,
                cached: true,
                ttl,
            };
        }

        let value = format!("value-for-{}", key);
        let _: () = conn.set_ex(&key, &value, 300).await.unwrap_or(());

        CacheEntry {
            key,
            value,
            cached: false,
            ttl: 300,
        }
    }
}

pub type Schema = RootNode<'static, QueryRoot, EmptyMutation<Context>, EmptySubscription<Context>>;

pub fn create_schema() -> Schema {
    Schema::new(QueryRoot, EmptyMutation::new(), EmptySubscription::new())
}
