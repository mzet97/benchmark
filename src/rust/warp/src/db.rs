use sqlx::PgPool;
use anyhow::Result;
use serde::{Deserialize, Serialize};

/// Pool size is part of the benchmark contract, not a per-implementation
/// choice: every implementation reads DB_POOL_MAX from the same ConfigMap so
/// the database access layer stops being a hidden variable in the ranking.
/// sqlx defaults to 10, which differed from every other implementation.
fn db_pool_max() -> u32 {
    std::env::var("DB_POOL_MAX")
        .ok()
        .and_then(|v| v.parse::<u32>().ok())
        .filter(|n| *n > 0)
        .unwrap_or(32)
}


#[derive(Debug)]
pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new(database_url: &str) -> Self {
        let pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(db_pool_max())
            .connect(database_url)
            .await
            .expect("Failed to connect to database");

        Self { pool }
    }

    pub async fn health_check(&self) -> Result<()> {
        sqlx::query("SELECT 1")
            .execute(&self.pool)
            .await
            .map(|_| ())
            .map_err(Into::into)
    }

    pub async fn get_user(&self, id: i32) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, first_name, last_name, age, created_at
             FROM users WHERE id = $1"
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    pub async fn get_complex_query(&self, days: i32) -> Result<Vec<ComplexUserStats>> {
        let rows = sqlx::query_as::<_, ComplexUserStats>(
            // Normative SQL, see contracts/rest/canonical-payloads.md. The
            // previous query selected a user_email/days_since_first_order
            // shape nothing else used and ordered without a tiebreak, so rows
            // with equal values came back in arbitrary order.
            r#"
            SELECT
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
            LIMIT 100"#
        )
        .bind(days)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows)
    }
}

#[derive(sqlx::FromRow, Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: i32,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub age: Option<i32>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

/// Mirrors UserOrderStats in contracts/grpc/benchmark.proto. The wire names
/// are camelCase, matching the proto3 JSON mapping of the snake_case proto
/// fields. See contracts/rest/canonical-payloads.md.
#[derive(sqlx::FromRow, Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ComplexUserStats {
    pub user_id: i32,
    pub user_name: String,
    pub total_orders: i64,
    // Cast to float8 in SQL rather than mapping Postgres NUMERIC: the
    // reference implementation carries these as float64 and sqlx would
    // otherwise need the bigdecimal feature to decode NUMERIC at all.
    pub total_value: f64,
    pub average_order_value: f64,
}

#[derive(Debug, Deserialize)]
pub struct SimpleQuery {
    pub id: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct ComplexQuery {
    pub days: Option<i32>,
}
