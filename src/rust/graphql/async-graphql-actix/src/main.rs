mod canonical;
mod cache;
mod db;
mod models;
mod schema;

use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use async_graphql::http::GraphQLResponse;
use schema::QueryRoot;
use std::sync::Arc;

struct AppState {
    schema: async_graphql::Schema<QueryRoot, async_graphql::EmptyMutation, async_graphql::EmptySubscription>,
}

async fn graphql_handler(
    state: web::Data<Arc<AppState>>,
    req: web::Json<async_graphql::Request>,
) -> HttpResponse {
    let response = state.schema.execute(req.into_inner()).await;
    HttpResponse::Ok().json(GraphQLResponse::from(response))
}

async fn health_handler() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({ "status": "ok" }))
}

#[actix_web::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let pool = db::create_pool().await?;
    db::ensure_schema(&pool).await?;

    let redis_conn = cache::create_connection().await?;

    let schema = async_graphql::Schema::build(QueryRoot, async_graphql::EmptyMutation, async_graphql::EmptySubscription)
        .data(pool)
        .data(redis_conn)
        .disable_introspection()
        .finish();

    let state = Arc::new(AppState { schema });
    let data = web::Data::new(state);

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .unwrap_or(8080);

    tracing::info!("GraphQL server listening on 0.0.0.0:{}", port);

    HttpServer::new(move || {
        App::new()
            .app_data(data.clone())
            .route("/graphql", web::post().to(graphql_handler))
            .route("/health", web::get().to(health_handler))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await?;

    Ok(())
}
