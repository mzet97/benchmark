mod canonical;

use actix_web::{web, App, HttpServer, HttpResponse};
use serde_json::json;
use std::sync::Arc;
use tokio::sync::Mutex;

// Database service using direct tokio_postgres connection
struct DbService {
    client: Arc<Mutex<tokio_postgres::Client>>,
}

impl DbService {
    async fn connect(database_url: &str) -> Self {
        // Parse URL manually to handle @ in password
        let after_scheme = database_url.split("://").nth(1).unwrap_or("");
        let last_at = after_scheme.rfind('@').unwrap_or(0);
        let user_pass = &after_scheme[..last_at];
        let host_port_db = &after_scheme[last_at + 1..];
        let user = user_pass.split(':').next().unwrap_or("app");
        let password = user_pass.split(':').nth(1).unwrap_or("");
        let host = host_port_db.split(':').next().unwrap_or("localhost");
        let port_db = host_port_db.split(':').nth(1).unwrap_or("5432/benchmark_api");
        let port: u16 = port_db.split('/').next().unwrap_or("5432").parse().unwrap_or(5432);
        let database = port_db.split('/').nth(1).unwrap_or("benchmark_api");

        let mut config = tokio_postgres::Config::new();
        config.user(user).password(password).host(host).port(port).dbname(database);

        let (client, connection) = config.connect(tokio_postgres::NoTls).await
            .expect("Failed to connect to PostgreSQL");

        tokio::spawn(async move {
            if let Err(e) = connection.await {
                eprintln!("PG connection error: {}", e);
            }
        });

        println!("PostgreSQL connected");
        DbService { client: Arc::new(Mutex::new(client)) }
    }

    async fn get_user(&self, id: i32) -> Option<serde_json::Value> {
        let client = self.client.lock().await;
        match client.query_opt(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
            &[&id],
        ).await {
            Ok(Some(row)) => Some(json!({
                "id": row.get::<_, i32>(0),
                "email": row.get::<_, String>(1),
                "first_name": row.get::<_, String>(2),
                "last_name": row.get::<_, String>(3),
                "age": row.get::<_, i32>(4),
                "created_at": row.get::<_, std::time::SystemTime>(5).duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_secs()
            })),
            _ => None,
        }
    }

    async fn get_complex(&self, days: i32) -> Vec<serde_json::Value> {
        let client = self.client.lock().await;
        match client.query(
            "SELECT u.id, u.email, COUNT(o.id) as cnt, COALESCE(SUM(o.total_amount),0) as total
             FROM users u JOIN orders o ON u.id=o.user_id
             WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
             GROUP BY u.id, u.email ORDER BY total DESC LIMIT 100",
            &[&days],
        ).await {
            Ok(rows) => rows.iter().map(|r| json!({
                "user_id": r.get::<_, i32>(0),
                "email": r.get::<_, String>(1),
                "order_count": r.get::<_, i64>(2),
                "total_amount": r.get::<_, f64>(3),
            })).collect(),
            Err(_) => vec![],
        }
    }

    async fn health_check(&self) -> bool {
        let client = self.client.lock().await;
        client.query_opt("SELECT 1", &[]).await.is_ok()
    }
}

// Cache service
struct CacheService {
    client: redis::Client,
}

impl CacheService {
    fn connect(redis_url: &str) -> Self {
        let client = redis::Client::open(redis_url).expect("Failed to create Redis client");
        println!("Redis connected");
        CacheService { client }
    }

    async fn get(&self, key: &str) -> Option<String> {
        let mut conn = match self.client.get_async_connection().await {
            Ok(c) => c,
            Err(_) => return None,
        };
        redis::cmd("GET").arg(key).query_async(&mut conn).await.ok()
    }

    async fn set(&self, key: &str, value: &str, ttl: i32) -> bool {
        let mut conn = match self.client.get_async_connection().await {
            Ok(c) => c,
            Err(_) => return false,
        };
        redis::cmd("SETEX").arg(key).arg(ttl).arg(value).query_async::<_, ()>(&mut conn).await.is_ok()
    }

    async fn health_check(&self) -> bool {
        let mut conn = match self.client.get_async_connection().await {
            Ok(c) => c,
            Err(_) => return false,
        };
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
        .json(json!({"status": status, "database": if db_ok {"connected"} else {"disconnected"}, "cache": if cache_ok {"connected"} else {"disconnected"}, "timestamp": chrono::Utc::now().to_rfc3339()}))
}

async fn json_endpoint(query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let n = canonical::item_count(query.get("n").map(String::as_str));

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    HttpResponse::Ok().json(json!({
        "items": canonical::build_items(n),
        "count": n,
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

async fn db_simple(data: web::Data<AppState>, query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let id: i32 = query.get("id").and_then(|s| s.parse().ok()).unwrap_or(1);
    match data.db.get_user(id).await {
        Some(user) => HttpResponse::Ok().json(user),
        None => HttpResponse::NotFound().json(json!({"error": format!("User with id {} not found", id)})),
    }
}

async fn db_complex(data: web::Data<AppState>, query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let days: i32 = query.get("days").and_then(|s| s.parse().ok()).unwrap_or(30);
    let results = data.db.get_complex(days).await;
    HttpResponse::Ok().json(json!({"period_days": days, "total_users": results.len(), "data": results, "timestamp": chrono::Utc::now().to_rfc3339()}))
}

async fn cache_handler(data: web::Data<AppState>, query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let key = query.get("key").cloned().unwrap_or_else(|| "test".to_string());
    if let Some(val) = data.cache.get(&key).await {
        return HttpResponse::Ok().json(json!({"key": key, "value": val, "cached": true, "timestamp": chrono::Utc::now().to_rfc3339()}));
    }
    let val = format!("Cached value for {} at {}", key, chrono::Utc::now().to_rfc3339());
    data.cache.set(&key, &val, 300).await;
    HttpResponse::Ok().json(json!({"key": key, "value": val, "cached": false, "timestamp": chrono::Utc::now().to_rfc3339()}))
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL is required");
    let redis_url = std::env::var("REDIS_URL").expect("REDIS_URL is required");
    let port: u16 = std::env::var("PORT").ok().and_then(|p| p.parse().ok()).unwrap_or(8080);

    println!("Connecting to PostgreSQL...");
    let db = DbService::connect(&database_url).await;
    let cache = CacheService::connect(&redis_url);
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
