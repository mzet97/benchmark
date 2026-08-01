use warp::{Filter, Rejection, Reply};
use serde_json::json;
use std::sync::Arc;
use chrono::Utc;

mod canonical;
mod db;
mod cache;

use db::Database;
use cache::Cache;

/// The TTL is part of the response contract; it must match the value written
/// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS: usize = 300;

#[tokio::main]
async fn main() {
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL is required");
    let redis_url = std::env::var("REDIS_URL").expect("REDIS_URL is required");

    let database = Arc::new(Database::new(&database_url).await);
    let cache = Arc::new(Cache::new(&redis_url).await);

    let health = warp::path!("health")
        .and(warp::get())
        .and(with_db(database.clone()))
        .and(with_cache(cache.clone()))
        .and_then(health_handler);

    let healthz = warp::path!("healthz")
        .and(warp::get())
        .map(|| warp::reply::json(&json!({ "status": "ok" })));

    let json = warp::path!("json")
        .and(warp::get())
        .and(warp::query::<std::collections::HashMap<String, String>>())
        .map(json_handler);

    let db_simple = warp::path!("db" / "simple")
        .and(warp::get())
        .and(warp::query::<db::SimpleQuery>())
        .and(with_db(database.clone()))
        .and_then(db_simple_handler);

    let db_complex = warp::path!("db" / "complex")
        .and(warp::get())
        .and(warp::query::<db::ComplexQuery>())
        .and(with_db(database))
        .and_then(db_complex_handler);

    let cache = warp::path!("cache")
        .and(warp::get())
        .and(warp::query::<cache::CacheQuery>())
        .and(with_cache(cache))
        .and_then(cache_handler);

    let index = warp::path::end()
        .map(|| {
            warp::reply::json(&json!({
                "name": "Benchmark API - Rust Warp",
                "version": "1.0.0",
                "runtime": "Rust",
                "framework": "Warp",
                "status": "running"
            }))
        });

    let routes = index.or(health).or(healthz).or(json).or(db_simple).or(db_complex).or(cache);

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);
    println!("Server starting on http://0.0.0.0:{}", port);
    warp::serve(routes).run(([0, 0, 0, 0], port)).await;
}

fn with_db(db: Arc<Database>) -> impl Filter<Extract = (Arc<Database>,), Error = std::convert::Infallible> + Clone {
    warp::any().map(move || db.clone())
}

fn with_cache(cache: Arc<Cache>) -> impl Filter<Extract = (Arc<Cache>,), Error = std::convert::Infallible> + Clone {
    warp::any().map(move || cache.clone())
}

async fn health_handler(db: Arc<Database>, cache: Arc<Cache>) -> Result<impl Reply, Rejection> {
    let db_healthy = db.health_check().await.is_ok();
    let cache_healthy = cache.ping().await.is_ok();

    let response = json!({
        "status": if db_healthy && cache_healthy { "healthy" } else { "unhealthy" },
        "version": "1.0.0",
        "timestamp": Utc::now().to_rfc3339(),
        "database": if db_healthy { "healthy" } else { "unhealthy" },
        "cache": if cache_healthy { "healthy" } else { "unhealthy" },
    });

    if !db_healthy || !cache_healthy {
        return Err(warp::reject::custom(AppError::ServiceUnavailable));
    }

    Ok(warp::reply::json(&response))
}

fn json_handler(params: std::collections::HashMap<String, String>) -> impl Reply {
    let n = canonical::item_count(params.get("n").map(String::as_str));

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    warp::reply::json(&json!({
        "items": canonical::build_items(n),
        "count": n,
        "timestamp": Utc::now().to_rfc3339()
    }))
}

async fn db_simple_handler(query: db::SimpleQuery, db: Arc<Database>) -> Result<impl Reply, Rejection> {
    let id = query.id.unwrap_or(1);
    match db.get_user(id).await {
        // The contract returns the user object itself, not an envelope.
        Ok(Some(user)) => Ok(warp::reply::json(&json!(user))),
        Ok(None) => Err(warp::reject::not_found()),
        Err(_) => Err(warp::reject::custom(AppError::Internal)),
    }
}

async fn db_complex_handler(query: db::ComplexQuery, db: Arc<Database>) -> Result<impl Reply, Rejection> {
    let days = query.days.unwrap_or(30);
    if days <= 0 || days > 365 {
        return Err(warp::reject::custom(AppError::BadRequest));
    }

    match db.get_complex_query(days).await {
        Ok(results) => {
            Ok(warp::reply::json(&json!({
                "periodDays": days,
                "totalUsers": results.len(),
                "data": results
            })))
        },
        Err(_) => Err(warp::reject::custom(AppError::Internal)),
    }
}

async fn cache_handler(query: cache::CacheQuery, cache: Arc<Cache>) -> Result<impl Reply, Rejection> {
    let key = query.key.unwrap_or_else(|| "test".to_string());
    let new_value = format!("cached-value-{}", uuid::Uuid::new_v4());

    match cache.get_or_set(&key, &new_value, CACHE_TTL_SECONDS).await {
        Ok((value, source)) => Ok(warp::reply::json(&json!({
            "key": key,
            "value": value,
            "cached": source == "cache",
            "ttl": CACHE_TTL_SECONDS,
            "timestamp": Utc::now().to_rfc3339()
        }))),
        Err(_) => Err(warp::reject::custom(AppError::Internal)),
    }
}

#[derive(Debug)]
enum AppError {
    BadRequest,
    Internal,
    ServiceUnavailable,
}
impl warp::reject::Reject for AppError {}
