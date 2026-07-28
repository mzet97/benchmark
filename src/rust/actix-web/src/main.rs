use actix_cors::Cors;
use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use log::{info, warn};
use redis::Client as RedisClient;
use serde_json::json;
use std::sync::Arc;

mod models;
mod services;

use models::*;
use services::{database::DatabaseService, cache::CacheService};

#[derive(Clone)]
struct AppState {
    db_service: Arc<DatabaseService>,
    cache_service: Arc<CacheService>,
}

#[get("/health")]
async fn health(state: web::Data<AppState>) -> impl Responder {
    // Check both database and Redis health
    let db_healthy = state.db_service.health_check().await.is_ok();
    let cache_healthy = state.cache_service.health_check().await.is_ok();

    if db_healthy && cache_healthy {
        HttpResponse::Ok().json(json!({
            "status": "healthy",
            "database": "connected",
            "cache": "connected",
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    } else {
        let mut errors = Vec::new();
        if !db_healthy {
            errors.push("database");
        }
        if !cache_healthy {
            errors.push("cache");
        }

        HttpResponse::ServiceUnavailable().json(json!({
            "status": "unhealthy",
            "errors": errors,
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))
    }
}

#[get("/json")]
async fn json_endpoint() -> impl Responder {
    let mut items = Vec::with_capacity(1000);
    for i in 0..1000 {
        items.push(json!({
            "id": i,
            "name": format!("Item {}", i),
            "description": format!("This is item number {}", i),
            "timestamp": chrono::Utc::now().to_rfc3339(),
            "random": format!("data-{}", uuid::Uuid::new_v4())
        }));
    }

    HttpResponse::Ok().json(json!({
        "items": items,
        "count": items.len(),
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

#[get("/db/simple")]
async fn db_simple(
    state: web::Data<AppState>,
    query: web::Query<std::collections::HashMap<String, String>>,
) -> impl Responder {
    let id: i32 = query
        .get("id")
        .and_then(|s| s.parse().ok())
        .unwrap_or(1);

    match state.db_service.get_user_by_id(id).await {
        Ok(Some(user)) => HttpResponse::Ok().json(user),
        Ok(None) => HttpResponse::NotFound().json(json!({
            "error": "User not found",
            "id": id
        })),
        Err(e) => {
            warn!("Database error: {}", e);
            HttpResponse::InternalServerError().json(json!({
                "error": "Database error"
            }))
        }
    }
}

#[get("/db/complex")]
async fn db_complex(
    state: web::Data<AppState>,
    query: web::Query<std::collections::HashMap<String, String>>,
) -> impl Responder {
    let days: i32 = query
        .get("days")
        .and_then(|s| s.parse().ok())
        .unwrap_or(30);

    match state.db_service.get_complex_orders(days).await {
        Ok(results) => HttpResponse::Ok().json(json!({
            "orders": results,
            "count": results.len(),
            "days": days,
            "timestamp": chrono::Utc::now().to_rfc3339()
        })),
        Err(e) => {
            warn!("Database error: {}", e);
            HttpResponse::InternalServerError().json(json!({
                "error": "Database error"
            }))
        }
    }
}

#[get("/cache")]
async fn cache_handler(
    state: web::Data<AppState>,
    query: web::Query<std::collections::HashMap<String, String>>,
) -> impl Responder {
    let key = query.get("key").cloned().unwrap_or_else(|| "test".to_string());

    match state.cache_service.get(&key).await {
        Ok(Some(value)) => {
            HttpResponse::Ok().json(json!({
                "key": key,
                "value": value,
                "source": "cache",
                "timestamp": chrono::Utc::now().to_rfc3339()
            }))
        }
        Ok(None) => {
            // Generate a new value and cache it
            let new_value = format!("cached-value-{}", uuid::Uuid::new_v4());
            if let Err(e) = state.cache_service.set(&key, &new_value, 300).await {
                warn!("Cache set error: {}", e);
            }

            HttpResponse::Ok().json(json!({
                "key": key,
                "value": new_value,
                "source": "generated",
                "timestamp": chrono::Utc::now().to_rfc3339()
            }))
        }
        Err(e) => {
            warn!("Cache error: {}", e);
            HttpResponse::InternalServerError().json(json!({
                "error": "Cache error"
            }))
        }
    }
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();

    // Load configuration from environment
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api".to_string());

    let redis_url = std::env::var("REDIS_URL")
        .unwrap_or_else(|_| "redis://:Admin@123@redis.home.arpa:30379".to_string());

    // Setup PostgreSQL connection
    info!("Connecting to PostgreSQL...");
    // Parse URL manually
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

    info!("DB: user={}, host={}, port={}, db={}", user, host, port, database);

    let mut config = tokio_postgres::Config::new();
    config.user(user).password(password).host(host).port(port).dbname(database);

    let (pg_client, pg_connection) = config.connect(tokio_postgres::NoTls)
        .await
        .expect("Failed to connect to PostgreSQL");

    tokio::spawn(async move {
        if let Err(e) = pg_connection.await {
            eprintln!("PostgreSQL connection error: {}", e);
        }
    });

    info!("PostgreSQL connected");

    // Setup Redis client
    info!("Connecting to Redis...");
    let redis_client = RedisClient::open(redis_url)
        .expect("Failed to create Redis client");

    // Create services
    let db_service = Arc::new(DatabaseService::new(pg_client));
    let cache_service = Arc::new(CacheService::new(redis_client));

    let app_state = AppState {
        db_service,
        cache_service,
    };

    let bind = std::env::var("BIND").unwrap_or_else(|_| "0.0.0.0:8080".to_string());
    let workers: usize = std::env::var("WORKERS").ok().and_then(|w| w.parse().ok()).unwrap_or(4);

    info!("Starting server on {} with {} workers", bind, workers);

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(app_state.clone()))
            .wrap(Cors::permissive())
            .service(health)
            .service(json_endpoint)
            .service(db_simple)
            .service(db_complex)
            .service(cache_handler)
    })
    .workers(workers)
    .bind(bind)?
    .run()
    .await?;

    Ok(())
}
