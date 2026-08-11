use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Json,
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use std::io::Write;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use chrono::Utc;

mod canonical;
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
    // The fallback filter is "error", not "...=debug".
    //
    // try_from_default_env() reads RUST_LOG, which the benchmark ConfigMap does
    // not set -- it only sets LOG_LEVEL, which no Rust crate reads. So this fell
    // back to tower_http=debug, and TraceLayer's DefaultOnRequest/OnResponse
    // emit at DEBUG: one span plus two formatted stdout events for every single
    // request. deploy/k3s/base/configmap.yaml puts the reason plainly --
    // per-request logging is a 2-3x difference between implementations and is
    // not what this benchmark measures. The ConfigMap now also sets RUST_LOG,
    // but the fallback must be quiet on its own.
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "error".into()),
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
        // No TraceLayer and no CorsLayer here.
        //
        // TraceLayer builds a span and emits two events per request; even
        // filtered out at ERROR the span construction is per-request work that
        // no other implementation in the matrix carries. CorsLayer::permissive()
        // added Access-Control-* headers to every response -- also unique to
        // this implementation, and CORS is not part of any contract in
        // contracts/rest/. Both are measurement noise, not framework behaviour.
        .with_state(state);

    // Parse address
    let port = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or_else(|e| {
            eprintln!("FATAL: Invalid PORT env var: {e}");
            let _ = std::io::stderr().flush();
            std::process::exit(1);
        });
    let addr = SocketAddr::from(([0, 0, 0, 0], port));

    // Start server
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .unwrap_or_else(|e| {
            eprintln!("FATAL: Failed to bind {addr}: {e}");
            let _ = std::io::stderr().flush();
            std::process::exit(1);
        });
    println!("🚀 Server listening on http://{}", addr);
    if let Err(e) = axum::serve(listener, app).await {
        eprintln!("FATAL: Server error: {e}");
        let _ = std::io::stderr().flush();
        std::process::exit(1);
    }
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
