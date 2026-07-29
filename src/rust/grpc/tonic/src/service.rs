use crate::cache::CacheClient;
use crate::db::DbPool;
use chrono::Utc;
use redis::AsyncCommands;
use tonic::{Request, Response, Status};
use uuid::Uuid;

pub mod benchmark {
    tonic::include_proto!("benchmark");
    pub const FILE_DESCRIPTOR_SET: &[u8] = include_bytes!("../benchmark_descriptor.bin");
}

use benchmark::benchmark_service_server::{BenchmarkService, BenchmarkServiceServer};
use benchmark::*;

pub struct BenchmarkServiceImpl {
    db: Option<DbPool>,
    cache: Option<CacheClient>,
}

impl BenchmarkServiceImpl {
    pub fn new(db: Option<DbPool>, cache: Option<CacheClient>) -> BenchmarkServiceServer<Self> {
        BenchmarkServiceServer::new(Self { db, cache })
    }
}

#[tonic::async_trait]
impl BenchmarkService for BenchmarkServiceImpl {
    async fn health(
        &self,
        _request: Request<HealthRequest>,
    ) -> Result<Response<HealthResponse>, Status> {
        let db_status = match &self.db {
            Some(pool) => match pool.client.query_one("SELECT 1", &[]).await {
                Ok(_) => "connected".to_string(),
                Err(e) => format!("error: {}", e),
            },
            None => "not configured".to_string(),
        };

        let cache_status = match &self.cache {
            Some(cache) => {
                let mut conn = cache.conn.clone();
                match redis::cmd("PING").query_async::<String>(&mut conn).await {
                    Ok(_) => "connected".to_string(),
                    Err(e) => format!("error: {}", e),
                }
            }
            None => "not configured".to_string(),
        };

        Ok(Response::new(HealthResponse {
            status: "ok".to_string(),
            version: env!("CARGO_PKG_VERSION").to_string(),
            timestamp: Utc::now().to_rfc3339(),
            database: db_status,
            cache: cache_status,
        }))
    }

    async fn get_json_items(
        &self,
        request: Request<JsonItemsRequest>,
    ) -> Result<Response<JsonItemsResponse>, Status> {
        let limit = request.into_inner().limit;
        let limit = if limit > 0 { limit } else { 1000 };

        let items: Vec<JsonItem> = (1..=limit)
            .map(|i| JsonItem {
                id: i,
                uuid: Uuid::new_v4().to_string(),
                name: format!("Item {}", i),
                email: format!("item{}@benchmark.local", i),
                created_at: Utc::now().to_rfc3339(),
                is_active: i % 10 != 0,
            })
            .collect();

        Ok(Response::new(JsonItemsResponse {
            count: items.len() as i32,
            items,
            timestamp: Utc::now().to_rfc3339(),
        }))
    }

    async fn get_user(
        &self,
        request: Request<GetUserRequest>,
    ) -> Result<Response<UserResponse>, Status> {
        let id = request.into_inner().id;

        let db = self.db.as_ref().ok_or_else(|| {
            Status::unavailable("Database not connected")
        })?;

        let row = db
            .client
            .query_one(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
                &[&id],
            )
            .await
            .map_err(|e| Status::not_found(format!("User not found: {}", e)))?;

        let created_at: std::time::SystemTime = row.get(5);
        let created_at: chrono::DateTime<Utc> = created_at.into();

        Ok(Response::new(UserResponse {
            id: row.get(0),
            email: row.get(1),
            first_name: row.get(2),
            last_name: row.get(3),
            age: row.get(4),
            created_at: created_at.to_rfc3339(),
        }))
    }

    async fn get_complex_orders(
        &self,
        request: Request<ComplexOrdersRequest>,
    ) -> Result<Response<ComplexOrdersResponse>, Status> {
        let days = request.into_inner().days;
        let days = if days > 0 { days } else { 30 };

        let db = self.db.as_ref().ok_or_else(|| {
            Status::unavailable("Database not connected")
        })?;

        let rows = db
            .client
            .query(
                "SELECT u.id, u.first_name || ' ' || u.last_name AS user_name, \
                 COUNT(o.id) AS total_orders, \
                 COALESCE(SUM(o.total), 0) AS total_value, \
                 COALESCE(AVG(o.total), 0) AS average_order_value \
                 FROM users u \
                 LEFT JOIN orders o ON o.user_id = u.id \
                   AND o.created_at >= NOW() - ($1 || ' days')::interval \
                 GROUP BY u.id, user_name \
                 HAVING COUNT(o.id) > 0 \
                 ORDER BY total_value DESC \
                 LIMIT 100",
                &[&days],
            )
            .await
            .map_err(|e| Status::internal(format!("Query error: {}", e)))?;

        let data: Vec<UserOrderStats> = rows
            .iter()
            .map(|row| UserOrderStats {
                user_id: row.get(0),
                user_name: row.get(1),
                total_orders: row.get(2),
                total_value: row.get::<_, f64>(3),
                average_order_value: row.get::<_, f64>(4),
            })
            .collect();

        let total_users = data.len() as i32;

        Ok(Response::new(ComplexOrdersResponse {
            period_days: days,
            total_users,
            data,
        }))
    }

    async fn get_cache_value(
        &self,
        request: Request<CacheRequest>,
    ) -> Result<Response<CacheResponse>, Status> {
        let key = request.into_inner().key;

        let cache = self.cache.as_ref().ok_or_else(|| {
            Status::unavailable("Cache not connected")
        })?;

        let cache_key = format!("benchmark:{}", key);
        let mut conn = cache.conn.clone();

        // Try cache hit first
        let cached: Option<String> = conn
            .get(&cache_key)
            .await
            .map_err(|e| Status::internal(format!("Redis error: {}", e)))?;

        if let Some(value) = cached {
            let ttl: i32 = conn.ttl(&cache_key).await.unwrap_or(-1);

            return Ok(Response::new(CacheResponse {
                key,
                value,
                cached: true,
                ttl,
                timestamp: Utc::now().to_rfc3339(),
            }));
        }

        // Cache miss: generate value and store
        let value = format!("benchmark_value_{}_{}", key, Utc::now().timestamp_millis());
        let _: () = conn
            .set_ex(&cache_key, &value, 300)
            .await
            .map_err(|e| Status::internal(format!("Redis error: {}", e)))?;

        Ok(Response::new(CacheResponse {
            key,
            value,
            cached: false,
            ttl: 300,
            timestamp: Utc::now().to_rfc3339(),
        }))
    }
}
