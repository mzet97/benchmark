use warp::{Filter, Rejection, Reply};
use serde_json::json;
use std::sync::Arc;
use chrono::Utc;

mod db;
mod cache;

use db::Database;
use cache::Cache;

#[tokio::main]
async fn main() {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api".to_string());
    let redis_url = std::env::var("REDIS_URL")
        .unwrap_or_else(|_| "redis://:Admin@123@redis.home.arpa:30379".to_string());

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

    println!("Server starting on http://0.0.0.0:3000");
    warp::serve(routes).run(([0, 0, 0, 0], 3000)).await;
}

fn with_db(db: Arc<Database>) -> impl Filter<Extract = (Arc<Database>,), Error = Rejection> + Clone {
    warp::any().map(move || db.clone())
}

fn with_cache(cache: Arc<Cache>) -> impl Filter<Extract = (Arc<Cache>,), Error = Rejection> + Clone {
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

fn json_handler() -> impl Reply {
    let mut items = Vec::new();
    for i in 0..1000 {
        items.push(json!({
            "id": i,
            "uuid": uuid::Uuid::new_v4().to_string(),
            "name": format!("User {}", i),
            "email": format!("user{}@example.com", i),
            "createdAt": Utc::now().to_rfc3339(),
            "isActive": true
        }));
    }
    warp::reply::json(&json!({
        "items": items,
        "count": items.len(),
        "timestamp": Utc::now().to_rfc3339()
    }))
}

async fn db_simple_handler(query: db::SimpleQuery, db: Arc<Database>) -> Result<impl Reply, Rejection> {
    let id = query.id.unwrap_or(1);
    match db.get_user(id).await {
        Ok(Some(user)) => Ok(warp::reply::json(&json!({
            "user": user,
            "timestamp": Utc::now().to_rfc3339()
        }))),
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
                "period_days": days,
                "total_users": results.len(),
                "data": results
            })))
        },
        Err(_) => Err(warp::reject::custom(AppError::Internal)),
    }
}

async fn cache_handler(query: cache::CacheQuery, cache: Arc<Cache>) -> Result<impl Reply, Rejection> {
    let key = query.key.unwrap_or_else(|| "test".to_string());
    let new_value = format!("cached-value-{}", uuid::Uuid::new_v4());

    match cache.get_or_set(&key, &new_value, 300).await {
        Ok((value, source)) => Ok(warp::reply::json(&json!({
            "key": key,
            "value": value,
            "source": source,
            "timestamp": Utc::now().to_rfc3339()
        }))),
        Err(_) => Err(warp::reject::custom(AppError::Internal)),
    }
}

#[derive(Debug)]
struct AppError;
impl warp::reject::Reject for AppError {}
impl AppError {
    fn internal() -> Self { Self }
    fn service_unavailable() -> Self { Self }
}
