use actix_web::{get, web, App, HttpResponse, HttpServer, Responder};
use serde_json::json;

#[get("/health")]
async fn health() -> impl Responder {
    HttpResponse::Ok().json(json!({"status": "ok"}))
}

#[get("/json")]
async fn json_endpoint() -> impl Responder {
    let items: Vec<_> = (0..1000).map(|i| json!({"id": i, "name": format!("Item {}", i)})).collect();
    HttpResponse::Ok().json(json!({"items": items, "count": 1000}))
}

#[get("/db/simple")]
async fn db_simple(query: web::Query<std::collections::HashMap<String, String>>) -> impl Responder {
    let id: i32 = query.get("id").and_then(|s| s.parse().ok()).unwrap_or(1);
    HttpResponse::Ok().json(json!({"id": id, "email": "test@example.com"}))
}

#[get("/cache")]
async fn cache_handler(query: web::Query<std::collections::HashMap<String, String>>) -> impl Responder {
    let key = query.get("key").cloned().unwrap_or_else(|| "test".to_string());
    HttpResponse::Ok().json(json!({"key": key, "value": "test-value", "cached": false}))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    println!("Starting on port {}", port);
    HttpServer::new(|| App::new().service(health).service(json_endpoint).service(db_simple).service(cache_handler))
        .bind(format!("0.0.0.0:{}", port))?
        .run()
        .await
}
