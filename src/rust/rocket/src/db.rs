use sqlx::{PgPool, Row, postgres::PgConnectOptions};
use anyhow::{Result, Context};
use serde::Serialize;

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

/// Build a PgConnectOptions from the component env vars (DB_HOST, DB_PORT,
/// DB_NAME, DB_USER, DB_PASSWORD) instead of passing DATABASE_URL straight to
/// sqlx. The secret's DATABASE_URL carries a percent-encoded password
/// (e.g. Admin%40123); sqlx does not percent-decode userinfo, so it sent the
/// literal "%40" to Postgres and authentication failed -- the .expect() then
/// panicked inside #[launch] before the server bound its port, producing
/// CrashLoopBackOff with no logs. Building the options from DB_PASSWORD
/// sidesteps percent-encoding entirely. Falls back to DATABASE_URL only if the
/// component vars are absent.
fn build_pg_options() -> PgConnectOptions {
    let host = std::env::var("DB_HOST");
    if let Ok(host) = host {
        let port = std::env::var("DB_PORT")
            .ok()
            .and_then(|p| p.parse::<u16>().ok())
            .unwrap_or(5432);
        let db = std::env::var("DB_NAME").unwrap_or_else(|_| "benchmark_api".to_string());
        let user = std::env::var("DB_USER").unwrap_or_else(|_| "app".to_string());
        let pass = std::env::var("DB_PASSWORD").expect("DB_PASSWORD is required when DB_HOST is set");
        return PgConnectOptions::new()
            .host(&host)
            .port(port)
            .database(&db)
            .username(&user)
            .password(&pass);
    }
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL or DB_HOST is required");
    database_url
        .parse::<PgConnectOptions>()
        .expect("Failed to parse DATABASE_URL as PgConnectOptions")
}


#[derive(Debug)]
pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new() -> Self {
        let options = build_pg_options();

        let pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(db_pool_max())
            .connect_with(options)
            .await
            .unwrap_or_else(|e| {
                eprintln!("FATAL: Failed to connect to database: {e}");
                panic!("Failed to connect to database: {e}");
            });

        Self { pool }
    }

    pub async fn health_check(&self) -> Result<()> {
        sqlx::query("SELECT 1")
            .fetch_one(&self.pool)
            .await
            .map(|_| ())
            .context("Database health check failed")
    }

    // sqlx::query! and query_as! are compile-time-checked macros: they need a
    // live DATABASE_URL or a committed .sqlx offline cache at *build* time,
    // which neither this repo nor the Dockerfile provides -- the crate could
    // never be compiled. The runtime API takes the same SQL without that
    // build-time dependency.
    pub async fn get_user(&self, id: i32) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, first_name, last_name, age, created_at
             FROM users WHERE id = $1",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Mirrors the reference implementation in src/go/fiber. The previous SQL
    /// used a C-style `INTERVAL '%s days'` placeholder, which Postgres reads
    /// as the literal string "%s days", and ordered only by total_value, so
    /// ties came back in arbitrary order and the response was not
    /// reproducible between runs.
    pub async fn get_complex_query(&self, days: i32) -> Result<Vec<ComplexUserStats>> {
        let rows = sqlx::query_as::<_, ComplexUserStats>(
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
            LIMIT 100
            "#,
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
