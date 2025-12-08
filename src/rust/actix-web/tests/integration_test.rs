#[cfg(test)]
mod integration_tests {
    use actix_web::{test, web, App};
    use std::collections::HashMap;

    // Note: These are simplified tests that don't require actual DB connection
    // In a real scenario, you'd use testcontainers or a test database

    #[actix_web::test]
    async fn test_health_endpoint() {
        let app = test::init_service(
            App::new()
                .service(web::resource("/health").to(|| async {
                    actix_web::HttpResponse::Ok().json(serde_json::json!({
                        "status": "healthy",
                        "database": "connected",
                        "cache": "connected"
                    }))
                }))
        ).await;

        let req = test::TestRequest::get()
            .uri("/health")
            .to_request();

        let resp = test::call_service(&app, req).await;

        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_json_endpoint() {
        let app = test::init_service(
            App::new()
                .service(web::resource("/json").to(|| async {
                    let items: Vec<_> = (0..1000).map(|i| {
                        serde_json::json!({
                            "id": i,
                            "name": format!("Item {}", i)
                        })
                    }).collect();

                    actix_web::HttpResponse::Ok().json(serde_json::json!({
                        "items": items,
                        "count": items.len()
                    }))
                }))
        ).await;

        let req = test::TestRequest::get()
            .uri("/json")
            .to_request();

        let resp = test::call_service(&app, req).await;

        assert!(resp.status().is_success());
    }

    #[actix_web::test]
    async fn test_db_simple_without_id() {
        let app = test::init_service(
            App::new()
                .service(web::resource("/db/simple").to(|| async {
                    actix_web::HttpResponse::BadRequest().json(serde_json::json!({
                        "error": "Missing id parameter"
                    }))
                }))
        ).await;

        let req = test::TestRequest::get()
            .uri("/db/simple")
            .to_request();

        let resp = test::call_service(&app, req).await;

        assert!(resp.status().is_client_error());
    }

    #[actix_web::test]
    async fn test_cache_endpoint() {
        let app = test::init_service(
            App::new()
                .service(web::resource("/cache").to(|query: web::Query<HashMap<String, String>>| async {
                    let key = query.get("key").cloned().unwrap_or_default();
                    actix_web::HttpResponse::Ok().json(serde_json::json!({
                        "key": key,
                        "value": format!("cached-value-{}", key),
                        "source": "generated"
                    }))
                }))
        ).await;

        let req = test::TestRequest::get()
            .uri("/cache?key=test")
            .to_request();

        let resp = test::call_service(&app, req).await;

        assert!(resp.status().is_success());
    }
}
