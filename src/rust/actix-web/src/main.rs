mod canonical;

use actix_web::{web, App, HttpServer, HttpResponse};
use deadpool_postgres::{Manager, ManagerConfig, Pool, RecyclingMethod};
use serde_json::json;
use std::io::Write;

/// Pool size is part of the benchmark contract, not a per-implementation
/// choice: every implementation reads DB_POOL_MAX from the same ConfigMap so
/// the data access layer stops being a hidden variable in the ranking.
fn db_pool_max() -> usize {
    std::env::var("DB_POOL_MAX")
        .ok()
        .and_then(|v| v.parse::<usize>().ok())
        .filter(|n| *n > 0)
        .unwrap_or(32)
}

/// The TTL is part of the response contract; it must match the value written
/// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS: i32 = 300;

/// Print a FATAL message to stderr (flushing so it is not lost when the process
/// aborts) and exit non-zero immediately.
///
/// Why this exists rather than `expect()`/`unwrap()`: a panic during startup
/// competes with the container being torn down, and its message can be lost
/// before it reaches the container logs -- CrashLoopBackOff with nothing to
/// diagnose (Anexo A.10). Going through `eprintln!` + an explicit
/// `stderr().flush()` + `process::exit(1)` guarantees the reason is readable.
/// `panic = "abort"` used to make this strictly necessary; it was removed from
/// the release profile in Fase 9.2, but an explicit flushed message on a
/// startup failure is still the difference between a diagnosable pod and a
/// silent one.
///
/// Same helper the axum, warp and rocket implementations use.
fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("FATAL: {}", msg.as_ref());
    let _ = std::io::stderr().flush();
    std::process::exit(1);
}

/// Normative SQL, shared verbatim with the other implementations. See
/// contracts/rest/canonical-payloads.md.
const COMPLEX_SQL: &str = "SELECT
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
             LIMIT 100";

/// Every database failure path collapses into this so handlers can answer 500
/// and the load generator's non_2xx counter registers the failure. Silently
/// degrading to an empty result behind a 200 is how a broken query ended up at
/// the top of the /db/complex ranking.
#[derive(Debug)]
enum DbError {
    Pool(deadpool_postgres::PoolError),
    Query(tokio_postgres::Error),
}

impl std::fmt::Display for DbError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DbError::Pool(e) => write!(f, "pool: {e}"),
            DbError::Query(e) => write!(f, "query: {e}"),
        }
    }
}

impl From<deadpool_postgres::PoolError> for DbError {
    fn from(e: deadpool_postgres::PoolError) -> Self {
        DbError::Pool(e)
    }
}

impl From<tokio_postgres::Error> for DbError {
    fn from(e: tokio_postgres::Error) -> Self {
        DbError::Query(e)
    }
}

/// This used to hold a single tokio_postgres::Client behind an Arc<Mutex<_>>,
/// which serialized every database request in the process: with 7 cores and
/// hundreds of concurrent connections, /db/simple and /db/complex queued one
/// at a time behind the mutex while every other implementation ran a pool.
/// Those numbers measured lock contention, not the framework.
struct DbService {
    pool: Pool,
}

impl DbService {
    async fn connect(database_url: &str) -> Self {
        // Use tokio_postgres's own URL parser (Config::from_str) instead of a
        // hand-rolled split(). The manual parser here did not percent-decode
        // the password, so DATABASE_URL with password Admin%40123 was sent to
        // Postgres literally and authentication failed for db_admin.
        // tokio_postgres's parser uses percent_encoding, which correctly yields
        // Admin@123. It also accepts the `sslmode=disable` query parameter.
        let config = database_url
            .parse::<tokio_postgres::Config>()
            .expect("Failed to parse DATABASE_URL");

        let manager = Manager::from_config(
            config,
            tokio_postgres::NoTls,
            ManagerConfig { recycling_method: RecyclingMethod::Fast },
        );
        let pool = Pool::builder(manager)
            .max_size(db_pool_max())
            .build()
            .expect("Failed to build PostgreSQL pool");

        println!("PostgreSQL pool ready");
        DbService { pool }
    }

    /// The normative SQL aliases its columns to the contract names; see
    /// contracts/rest/canonical-payloads.md. createdAt used to go out as epoch
    /// seconds -- a number, where every other implementation sent an ISO 8601
    /// string.
    ///
    /// Returns Err on any driver/pool failure so the caller can answer 5xx.
    /// It used to collapse every error into None, which the handler turned into
    /// a 404: a broken database read was indistinguishable from a missing row,
    /// and the load generator's non_2xx counter never saw the difference.
    async fn get_user(&self, id: i32) -> Result<Option<serde_json::Value>, DbError> {
        let client = self.pool.get().await?;
        // prepare_cached, not query_opt(&str): tokio_postgres::Client::query*
        // called with a &str runs Parse+Describe on every single call, so each
        // request paid two round-trips to Postgres where every pooled
        // implementation (HikariCP, sqlx, pgx) pays one. deadpool's
        // per-connection statement cache is what closes that gap.
        let stmt = client.prepare_cached(
            "SELECT id, email, first_name, last_name, age, created_at
             FROM users WHERE id = $1",
        ).await?;
        let row = client.query_opt(&stmt, &[&id]).await?;
        Ok(row.map(|row| json!({
            "id": row.get::<_, i32>(0),
            "email": row.get::<_, String>(1),
            "firstName": row.get::<_, String>(2),
            "lastName": row.get::<_, String>(3),
            "age": row.get::<_, Option<i32>>(4),
            "createdAt": row.get::<_, chrono::NaiveDateTime>(5).and_utc().to_rfc3339()
        })))
    }

    /// Normative SQL. The previous query grouped by u.email, selected only
    /// four columns under names nothing else used, and ordered without a
    /// tiebreak, so rows with equal totals came back in arbitrary order.
    async fn get_complex(&self, days: i32) -> Result<Vec<serde_json::Value>, DbError> {
        let client = self.pool.get().await?;
        let stmt = client.prepare_cached(COMPLEX_SQL).await?;
        // $1 is bound as f64, not i32. Postgres has no `interval * int4`
        // operator, so when tokio-postgres prepares this statement without
        // declaring parameter types the server infers $1 as float8 -- and
        // `impl ToSql for i32` only accepts INT4, so every execution failed
        // with "cannot convert between the Rust type i32 and the Postgres type
        // float8". The old code mapped that error to an empty Vec behind a
        // 200 OK, which is why this endpoint measured 32,777 rps at 220
        // bytes/response while every other implementation returned ~11 kB at
        // ~860 rps. sqlx-based siblings (warp/axum/rocket) declare the
        // parameter OIDs in Parse, so Postgres resolves int4 -> float8 through
        // its implicit cast and they were never affected.
        //
        // Binding f64 keeps the SQL byte-identical to the normative text in
        // contracts/rest/canonical-payloads.md; `days` is still echoed back as
        // an integer in periodDays.
        let days_interval = f64::from(days);
        let rows = client.query(&stmt, &[&days_interval]).await?;
        Ok(rows.iter().map(|r| json!({
            "userId": r.get::<_, i32>(0),
            "userName": r.get::<_, String>(1),
            "totalOrders": r.get::<_, i64>(2),
            "totalValue": r.get::<_, f64>(3),
            "averageOrderValue": r.get::<_, f64>(4),
        })).collect())
    }

    async fn health_check(&self) -> bool {
        match self.pool.get().await {
            Ok(client) => match client.prepare_cached("SELECT 1").await {
                Ok(stmt) => client.query_opt(&stmt, &[]).await.is_ok(),
                Err(_) => false,
            },
            Err(_) => false,
        }
    }
}

/// Redis access for the actix-web implementation.
///
/// Holds one MultiplexedConnection, established at startup, and clones it per
/// command -- the clone is a cheap handle onto the same socket, and the driver
/// pipelines concurrent commands from every worker thread over it. This is the
/// same model Lettuce gives the JVM implementations and the same one the Rust
/// gRPC implementations already used.
///
/// It previously called Client::get_async_connection() inside get/set/ping,
/// which opens a brand new TCP connection *per request*. At 100 concurrent
/// connections that measured the handshake and the resulting TIME_WAIT
/// pileup, not Redis: /cache ran at 1,636 rps with a 109 ms p99 against
/// 186,825 rps for the multiplexed http4k implementation, and it was also the
/// dominant cost in /health.
struct CacheService {
    conn: redis::aio::MultiplexedConnection,
}

impl CacheService {
    async fn connect(redis_url: &str) -> Self {
        let client = redis::Client::open(redis_url)
            .unwrap_or_else(|e| die(format!("Failed to build Redis client: {e}")));
        // Unlike Client::open, this actually opens the socket, so an
        // unreachable Redis now fails at startup instead of on the first
        // request. That is the right trade for a benchmark -- a pod serving
        // /cache without a cache produces numbers that mean nothing -- but it
        // has to fail with a readable log line, hence die() over expect().
        let conn = client
            .get_multiplexed_async_connection()
            .await
            .unwrap_or_else(|e| die(format!("Failed to open multiplexed Redis connection: {e}")));
        println!("Redis connected");
        CacheService { conn }
    }

    async fn get(&self, key: &str) -> Option<String> {
        let mut conn = self.conn.clone();
        redis::cmd("GET").arg(key).query_async(&mut conn).await.ok()
    }

    async fn set(&self, key: &str, value: &str, ttl: i32) -> bool {
        let mut conn = self.conn.clone();
        redis::cmd("SETEX").arg(key).arg(ttl).arg(value).query_async::<_, ()>(&mut conn).await.is_ok()
    }

    async fn health_check(&self) -> bool {
        let mut conn = self.conn.clone();
        redis::cmd("PING").query_async::<_, String>(&mut conn).await.is_ok()
    }
}

struct AppState {
    db: DbService,
    cache: CacheService,
}

async fn health(data: web::Data<AppState>) -> HttpResponse {
    let db_ok = data.db.health_check().await;
    let cache_ok = data.cache.health_check().await;
    let status = if db_ok && cache_ok { "healthy" } else { "unhealthy" };
    let code = if db_ok && cache_ok { 200 } else { 503 };
    HttpResponse::build(actix_web::http::StatusCode::from_u16(code).unwrap_or(actix_web::http::StatusCode::SERVICE_UNAVAILABLE))
        .json(json!({"status": status, "version": "1.0.0", "database": if db_ok {"connected"} else {"disconnected"}, "cache": if cache_ok {"connected"} else {"disconnected"}, "timestamp": chrono::Utc::now().to_rfc3339()}))
}

async fn json_endpoint(query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let n = canonical::item_count(query.get("n").map(String::as_str));

    // canonical::envelope, not json!{...}: see canonical::JsonEnvelope.
    HttpResponse::Ok().json(canonical::envelope(n))
}

async fn db_simple(data: web::Data<AppState>, query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let id: i32 = query.get("id").and_then(|s| s.parse().ok()).unwrap_or(1);
    match data.db.get_user(id).await {
        Ok(Some(user)) => HttpResponse::Ok().json(user),
        Ok(None) => HttpResponse::NotFound().json(json!({"error": format!("User with id {} not found", id)})),
        Err(e) => {
            log::error!("/db/simple failed for id={id}: {e}");
            HttpResponse::InternalServerError().json(json!({"error": "database error"}))
        }
    }
}

async fn db_complex(data: web::Data<AppState>, query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let days: i32 = query.get("days").and_then(|s| s.parse().ok()).unwrap_or(30);
    match data.db.get_complex(days).await {
        Ok(results) => HttpResponse::Ok()
            .json(json!({"periodDays": days, "totalUsers": results.len(), "data": results})),
        Err(e) => {
            log::error!("/db/complex failed for days={days}: {e}");
            HttpResponse::InternalServerError().json(json!({"error": "database error"}))
        }
    }
}

async fn cache_handler(data: web::Data<AppState>, query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let key = query.get("key").cloned().unwrap_or_else(|| "test".to_string());
    if let Some(val) = data.cache.get(&key).await {
        return HttpResponse::Ok().json(json!({"key": key, "value": val, "cached": true, "ttl": CACHE_TTL_SECONDS, "timestamp": chrono::Utc::now().to_rfc3339()}));
    }
    let val = format!("Cached value for {} at {}", key, chrono::Utc::now().to_rfc3339());
    data.cache.set(&key, &val, CACHE_TTL_SECONDS).await;
    HttpResponse::Ok().json(json!({"key": key, "value": val, "cached": false, "ttl": CACHE_TTL_SECONDS, "timestamp": chrono::Utc::now().to_rfc3339()}))
}

/// `actix_web::main`, not `tokio::main`. actix-server does run under a plain
/// Tokio runtime (worker.rs takes its `(None, Some(rt_handle))` branch and
/// still spawns one thread with its own current-thread runtime per worker), so
/// this was not a correctness bug -- but TOKIO_WORKER_THREADS=40 from the
/// ConfigMap then built a 40-thread multi-threaded runtime that only ever ran
/// startup, on top of actix's own 40 workers. 80 threads for 40 cores.
/// TOKIO_WORKER_THREADS does not size actix's workers; available_parallelism()
/// does, and it reads the cgroup quota.
#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL is required");
    let redis_url = std::env::var("REDIS_URL").expect("REDIS_URL is required");
    let port: u16 = std::env::var("PORT").ok().and_then(|p| p.parse().ok()).unwrap_or(8080);

    println!("Connecting to PostgreSQL...");
    let db = DbService::connect(&database_url).await;
    let cache = CacheService::connect(&redis_url).await;
    println!("Starting server on 0.0.0.0:{}", port);

    let data = web::Data::new(AppState { db, cache });

    HttpServer::new(move || {
        App::new()
            .app_data(data.clone())
            .route("/health", web::get().to(health))
            .route("/json", web::get().to(json_endpoint))
            .route("/db/simple", web::get().to(db_simple))
            .route("/db/complex", web::get().to(db_complex))
            .route("/cache", web::get().to(cache_handler))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
