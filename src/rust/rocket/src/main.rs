#[macro_use]
extern crate rocket;

use rocket::{
    http::Status,
    response::status::Custom,
    serde::json::Json,
    State,
};
use serde::{Deserialize, Serialize};
use chrono::Utc;
use std::io::Write;

mod canonical;
mod db;
mod cache;
mod handlers;

use db::Database;
use cache::Cache;

#[get("/")]
fn index() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "name": "Benchmark API - Rust Rocket",
        "version": "1.0.0",
        "description": "High-performance REST API benchmark",
        "runtime": "Rust",
        "framework": "Rocket",
        "endpoints": {
            "health": "/health",
            "json": "/json",
            "db_simple": "/db/simple?id=1",
            "db_complex": "/db/complex?days=30",
            "cache": "/cache?key=test"
        },
        "status": "running"
    }))
}

#[get("/health")]
async fn health(db: &State<Database>, cache: &State<Cache>) -> Result<Json<serde_json::Value>, Status> {
    let db_healthy = db.health_check().await.is_ok();
    let cache_healthy = cache.ping().await.is_ok();

    let response = serde_json::json!({
        "status": if db_healthy && cache_healthy { "healthy" } else { "unhealthy" },
        "version": "1.0.0",
        "timestamp": Utc::now().to_rfc3339(),
        "database": if db_healthy { "healthy" } else { "unhealthy" },
        "cache": if cache_healthy { "healthy" } else { "unhealthy" },
    });

    if !db_healthy || !cache_healthy {
        return Err(Status::ServiceUnavailable);
    }

    Ok(Json(response))
}

#[get("/healthz")]
fn healthz() -> Json<serde_json::Value> {
    Json(serde_json::json!({ "status": "ok" }))
}

#[get("/json?<n>")]
fn json_endpoint(n: Option<usize>) -> Json<serde_json::Value> {
    let n = n.map_or(canonical::DEFAULT_JSON_ITEMS, |v| v.min(canonical::MAX_JSON_ITEMS));

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    Json(serde_json::json!({
        "items": canonical::build_items(n),
        "count": n,
        "timestamp": Utc::now().to_rfc3339()
    }))
}

#[get("/db/simple?<id>")]
async fn db_simple(db: &State<Database>, id: Option<i32>) -> Result<Json<serde_json::Value>, Status> {
    let id = id.unwrap_or(1);
    match db.get_user(id).await {
        // The contract returns the user object itself, not an envelope.
        Ok(Some(user)) => Ok(Json(serde_json::json!(user))),
        Ok(None) => Err(Status::NotFound),
        Err(_) => Err(Status::InternalServerError),
    }
}

#[get("/db/complex?<days>")]
async fn db_complex(db: &State<Database>, days: Option<i32>) -> Result<Json<serde_json::Value>, Status> {
    let days = days.unwrap_or(30);
    if days <= 0 || days > 365 {
        return Err(Status::BadRequest);
    }

    match db.get_complex_query(days).await {
        Ok(results) => {
            Ok(Json(serde_json::json!({
                "periodDays": days,
                "totalUsers": results.len(),
                "data": results
            })))
        },
        Err(_) => Err(Status::InternalServerError),
    }
}

#[get("/cache?<key>")]
async fn cache_endpoint(cache: &State<Cache>, key: Option<String>) -> Result<Json<serde_json::Value>, Status> {
    let key = key.unwrap_or_else(|| "test".to_string());
    let new_value = format!("cached-value-{}", uuid::Uuid::new_v4());

    match cache.get_or_set(&key, &new_value, 300).await {
        Ok((value, source)) => Ok(Json(serde_json::json!({
            "key": key,
            "value": value,
            "cached": source == "cache",
            "ttl": 300,
            "timestamp": Utc::now().to_rfc3339()
        }))),
        Err(_) => Err(Status::InternalServerError),
    }
}

#[launch]
async fn rocket() -> _ {
    dotenvy::dotenv().ok();

    // Database::new() builds the connection from DB_HOST/DB_PORT/DB_NAME/
    // DB_USER/DB_PASSWORD rather than DATABASE_URL, to sidestep the
    // percent-encoded password that sqlx does not decode. See db.rs.
    let redis_url = match std::env::var("REDIS_URL") {
        Ok(u) => u,
        Err(_) => {
            eprintln!("FATAL: REDIS_URL is required");
            let _ = std::io::stderr().flush();
            std::process::exit(1);
        }
    };

    let database = Database::new().await;
    let cache = Cache::new(&redis_url).await;

    rocket::build()
        .attach(rocket::shield::Shield::new())
        .manage(database)
        .manage(cache)
        .mount("/", routes![
            index,
            health,
            healthz,
            json_endpoint,
            db_simple,
            db_complex,
            cache_endpoint
        ])
}
