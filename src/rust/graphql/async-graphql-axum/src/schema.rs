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
                // Normative SQL, see contracts/rest/canonical-payloads.md. The
                // previous query aggregated o.amount, a column the schema does not
                // have; it wrote ($1 || ' days')::interval with a string bind; it
                // ordered without a tiebreak; and it had no LIMIT, so it returned
                // every user rather than the 100 the contract fixes.
                "SELECT
                    u.id AS user_id,
                    u.first_name || ' ' || u.last_name AS user_name,
                    COUNT(o.id) AS total_orders,
                    COALESCE(SUM(o.total_amount), 0)::float8 AS total_value,
                    COALESCE(AVG(o.total_amount), 0)::float8 AS average_order_value
                 FROM users u
                 INNER JOIN orders o ON u.id = o.user_id
                    WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
                 GROUP BY u.id, u.first_name, u.last_name
                 ORDER BY total_orders DESC, u.id
                 LIMIT 100",
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
                // rust_decimal::Decimal does not implement FromSql for
                // tokio-postgres, so this never compiled. The query casts to
                // float8 instead, which is also what the reference
                // implementation carries.
                total_value: r.get(3),
                average_order_value: r.get(4),
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
