use async_graphql::Context;
use chrono::Utc;
use deadpool_postgres::Pool;
use redis::aio::ConnectionManager;
use redis::AsyncCommands;

use crate::models::*;

pub struct QueryRoot;

#[async_graphql::Object]
impl QueryRoot {
    async fn health(&self, ctx: &Context<'_>) -> Health {
        let pool = ctx.data::<Pool>().unwrap();
        let redis = ctx.data::<ConnectionManager>().unwrap();

        let db_status = match pool.get().await {
            Ok(conn) => match conn.query_one("SELECT 1", &[]).await {
                Ok(_) => "connected".to_string(),
                Err(_) => "error".to_string(),
            },
            Err(_) => "disconnected".to_string(),
        };

        let cache_status = {
            let mut conn = redis.clone();
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

    async fn json_items(&self, _ctx: &Context<'_>, limit: Option<i32>) -> JsonItemsResult {
        let count = limit.unwrap_or(1000);
        let items: Vec<JsonItem> = (1..=count)
            .map(|i| JsonItem {
                id: i,
                uuid: uuid::Uuid::new_v4().to_string(),
                name: format!("Item {}", i),
                email: format!("item{}@example.com", i),
                created_at: Utc::now().to_rfc3339(),
                is_active: i % 2 == 0,
            })
            .collect();

        JsonItemsResult {
            count: items.len() as i32,
            items,
            timestamp: Utc::now().to_rfc3339(),
        }
    }

    async fn user(&self, ctx: &Context<'_>, id: i32) -> Option<User> {
        let pool = ctx.data::<Pool>().unwrap();
        let conn = pool.get().await.ok()?;

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

    async fn complex_orders(&self, ctx: &Context<'_>, days: Option<i32>) -> ComplexOrdersResult {
        let period_days = days.unwrap_or(30);
        let pool = ctx.data::<Pool>().unwrap();
        let conn = pool.get().await.unwrap();

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

    async fn cache(&self, ctx: &Context<'_>, key: String) -> CacheEntry {
        let redis = ctx.data::<ConnectionManager>().unwrap();
        let mut conn = redis.clone();

        // Try to get from cache
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

        // Generate value on miss
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
