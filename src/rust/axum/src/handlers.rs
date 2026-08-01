use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Json,
};
use serde::Deserialize;
use serde_json::Value;
use std::collections::HashMap;

use crate::services::{DatabaseService, CacheService};

#[derive(Debug, Deserialize)]
pub struct SimpleQuery {
    pub id: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct ComplexQuery {
    pub days: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct CacheQuery {
    pub key: Option<String>,
}

pub async fn health_check(
    State(state): State<crate::AppState>,
) -> Result<Json<Value>, StatusCode> {
    let db_healthy = state.database.health_check().await.is_ok();
    let cache_healthy = state.cache.ping().await.is_ok();

    let response = serde_json::json!({
        "status": if db_healthy && cache_healthy { "healthy" } else { "unhealthy" },
        "version": "1.0.0",
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "database": if db_healthy { "healthy" } else { "unhealthy" },
        "cache": if cache_healthy { "healthy" } else { "unhealthy" },
    });

    if !db_healthy || !cache_healthy {
        return Err(StatusCode::SERVICE_UNAVAILABLE);
    }

    Ok(Json(response))
}

pub async fn healthz() -> Json<Value> {
    Json(serde_json::json!({ "status": "ok" }))
}

pub async fn json_endpoint(Query(params): Query<HashMap<String, String>>) -> Json<Value> {
    let n = crate::canonical::item_count(params.get("n").map(String::as_str));

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    Json(serde_json::json!({
        "items": crate::canonical::build_items(n),
        "count": n,
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

pub async fn db_simple(
    State(state): State<crate::AppState>,
    Query(query): Query<SimpleQuery>,
) -> Result<Json<Value>, StatusCode> {
    let id = query.id.unwrap_or(1);
    
    match state.database.get_user(id).await {
        // The contract returns the user object itself, not an envelope.
        Ok(Some(user)) => Ok(Json(serde_json::json!(user))),
        Ok(None) => Err(StatusCode::NOT_FOUND),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

pub async fn db_complex(
    State(state): State<crate::AppState>,
    Query(query): Query<ComplexQuery>,
) -> Result<Json<Value>, StatusCode> {
    let days = query.days.unwrap_or(30);

    if days <= 0 || days > 365 {
        return Err(StatusCode::BAD_REQUEST);
    }

    match state.database.get_complex_query(days).await {
        Ok(results) => {
            Ok(Json(serde_json::json!({
                "periodDays": days,
                "totalUsers": results.len(),
                "data": results
            })))
        },
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

pub async fn cache_endpoint(
    State(state): State<crate::AppState>,
    Query(query): Query<CacheQuery>,
) -> Result<Json<Value>, StatusCode> {
    let key = query.key.unwrap_or_else(|| "test".to_string());
    let new_value = format!("cached-value-{}", uuid::Uuid::new_v4());

    match state.cache.get_or_set(&key, &new_value, 300).await {
        Ok((value, source)) => Ok(Json(serde_json::json!({
            "key": key,
            "value": value,
            "cached": source == "cache",
            "ttl": 300,
            "timestamp": chrono::Utc::now().to_rfc3339()
        }))),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}
