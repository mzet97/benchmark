mod cache;
mod db;
mod models;
mod schema;

use axum::{extract::State, http::StatusCode, response::IntoResponse, routing::post, Json, Router};
use schema::QueryRoot;
use std::sync::Arc;

struct AppState {
    schema: async_graphql::Schema<QueryRoot, async_graphql::EmptyMutation, async_graphql::EmptySubscription>,
}

async fn graphql_handler(
    State(state): State<Arc<AppState>>,
    Json(req): Json<async_graphql::Request>,
) -> impl IntoResponse {
    let response = state.schema.execute(req).await;
    (StatusCode::OK, Json(response))
}

#[tokio::main]
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

    let app = Router::new()
        .route("/graphql", post(graphql_handler))
        .with_state(state);

    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port);

    tracing::info!("GraphQL server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
