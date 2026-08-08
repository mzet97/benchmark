use sqlx::{PgPool, Row, postgres::PgConnectOptions};
use redis::Client as RedisClient;
use anyhow::{Result, Context};
use std::env;
use std::io::Write;
use serde::Serialize;

/// Print a FATAL message to stderr (flushing so it is not lost when the
/// process aborts) and exit non-zero immediately.
///
/// Why this exists: Cargo.toml sets `[profile.release] panic = "abort"` plus
/// `strip = true`. A panic hook's message can be truncated or never flushed
/// before abort runs, so on a real crash the container died with *zero* log
/// output -- CrashLoopBackOff with nothing to diagnose. Going through
/// `eprintln!` + an explicit `stderr().flush()` + `process::exit(1)` instead
/// of `panic!`/`expect()`/`unwrap()` guarantees the message reaches the
/// container logs before the process is torn down.
fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("FATAL: {}", msg.as_ref());
    let _ = std::io::stderr().flush();
    std::process::exit(1);
}

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
/// panicked before tracing was initialized, producing CrashLoopBackOff with
/// no logs. Building the options from DB_PASSWORD sidesteps percent-encoding
/// entirely. Falls back to DATABASE_URL only if the component vars are absent.
fn build_pg_options() -> PgConnectOptions {
    let host = env::var("DB_HOST");
    if let Ok(host) = host {
        let port = env::var("DB_PORT")
            .ok()
            .and_then(|p| p.parse::<u16>().ok())
            .unwrap_or(5432);
        let db = env::var("DB_NAME").unwrap_or_else(|_| "benchmark_api".to_string());
        let user = env::var("DB_USER").unwrap_or_else(|_| "app".to_string());
        let pass = match env::var("DB_PASSWORD") {
            Ok(p) => p,
            Err(_) => die("DB_PASSWORD is required when DB_HOST is set"),
        };
        return PgConnectOptions::new()
            .host(&host)
            .port(port)
            .database(&db)
            .username(&user)
            .password(&pass);
    }
    let database_url = match env::var("DATABASE_URL") {
        Ok(u) => u,
        Err(_) => die("Neither DB_HOST nor DATABASE_URL is set; cannot connect to the database"),
    };
    match database_url.parse::<PgConnectOptions>() {
        Ok(opts) => opts,
        Err(e) => die(format!("Failed to parse DATABASE_URL as PgConnectOptions: {e}")),
    }
}


#[derive(Debug, Clone)]
pub struct DatabaseService {
    pool: PgPool,
}

impl DatabaseService {
    pub async fn new() -> Self {
        let options = build_pg_options();

        let pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(db_pool_max())
            .connect_with(options)
            .await
            .unwrap_or_else(|e| {
                die(format!("Failed to connect to database: {e}"));
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

#[derive(Debug, Clone)]
pub struct CacheService {
    client: RedisClient,
}

impl CacheService {
    pub async fn new() -> Self {
        let redis_url = match env::var("REDIS_URL") {
            Ok(u) => u,
            Err(_) => die("REDIS_URL is required"),
        };

        let client = RedisClient::open(redis_url)
            .unwrap_or_else(|e| die(format!("Failed to build Redis client: {e}")));

        Self { client }
    }

    pub async fn ping(&self) -> Result<()> {
        let mut conn = self.client.get_async_connection().await?;
        redis::cmd("PING")
            .query_async::<_, String>(&mut conn)
            .await?;
        Ok(())
    }

    pub async fn get_or_set(&self, key: &str, value: &str, ttl_seconds: usize) -> Result<(String, String)> {
        let mut conn = self.client.get_async_connection().await?;

        let existing: Option<String> = redis::cmd("GET")
            .arg(key)
            .query_async(&mut conn)
            .await?;

        if let Some(existing_value) = existing {
            Ok((existing_value, "cache".to_string()))
        } else {
            redis::cmd("SETEX")
                .arg(key)
                .arg(ttl_seconds)
                .arg(value)
                .query_async::<_, String>(&mut conn)
                .await?;
            Ok((value.to_string(), "generated".to_string()))
        }
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
    pub created_at: chrono::NaiveDateTime,
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
