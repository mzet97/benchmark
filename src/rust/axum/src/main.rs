use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Json,
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use chrono::Utc;

mod handlers;
mod services;
mod models;

use services::{DatabaseService, CacheService};
use handlers::*;

#[derive(Clone)]
struct AppState {
    database: DatabaseService,
    cache: CacheService,
}

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "benchmark_axum=debug,tower_http=debug,axum=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Initialize services
    let database = DatabaseService::new().await;
    let cache = CacheService::new().await;

    let state = AppState { database, cache };

    // Build router
    let app = Router::new()
        .route("/", get(root))
        .route("/health", get(health_check))
        .route("/healthz", get(healthz))
        .route("/json", get(json_endpoint))
        .route("/db/simple", get(db_simple))
        .route("/db/complex", get(db_complex))
        .route("/cache", get(cache_endpoint))
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Parse address
    let addr = SocketAddr::from((
        [0, 0, 0, 0],
        std::env::var("PORT")
            .unwrap_or_else(|_| "3000".to_string())
            .parse::<u16>()
            .unwrap(),
    ));

    // Start server
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    println!("🚀 Server listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}

async fn root() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "name": "Benchmark API - Rust Axum",
        "version": "1.0.0",
        "description": "High-performance REST API benchmark",
        "runtime": "Rust",
        "framework": "Axum",
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
