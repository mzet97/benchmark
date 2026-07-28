use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde_json::json;

async fn health() -> HttpResponse {
    HttpResponse::Ok().json(json!({"status": "ok"}))
}

async fn json_endpoint() -> HttpResponse {
    let items: Vec<_> = (0..1000).map(|i| json!({"id": i, "name": format!("Item {}", i)})).collect();
    HttpResponse::Ok().json(json!({"items": items, "count": 1000}))
}

async fn db_simple(query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let id: i32 = query.get("id").and_then(|s| s.parse().ok()).unwrap_or(1);
    HttpResponse::Ok().json(json!({"id": id, "email": "test@example.com"}))
}

async fn cache_handler(query: web::Query<std::collections::HashMap<String, String>>) -> HttpResponse {
    let key = query.get("key").cloned().unwrap_or_else(|| "test".to_string());
    HttpResponse::Ok().json(json!({"key": key, "value": "test-value", "cached": false}))
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port: u16 = std::env::var("PORT").ok().and_then(|p| p.parse().ok()).unwrap_or(8080);
    println!("Starting on port {}", port);

    HttpServer::new(|| {
        App::new()
            .route("/health", web::get().to(health))
            .route("/json", web::get().to(json_endpoint))
            .route("/db/simple", web::get().to(db_simple))
            .route("/cache", web::get().to(cache_handler))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
