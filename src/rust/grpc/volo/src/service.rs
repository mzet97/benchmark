use crate::cache::CacheClient;
use crate::db::DbPool;
use chrono::Utc;
use redis::AsyncCommands;
use uuid::Uuid;
use volo_grpc::{Request, Response, Status};

include!(concat!(env!("OUT_DIR"), "/benchmark.rs"));

// The volo-build-generated code nests the proto package as
// `benchmark::benchmark::<items>` (outer file module -> inner package module).
// Re-export the generated items so the rest of the crate (main.rs) shares a
// single copy of these types instead of re-including the generated file.
pub use benchmark::benchmark::{
    BenchmarkService, BenchmarkServiceServer,
    BenchmarkServiceRequestRecv, BenchmarkServiceResponseSend,
    CacheRequest, CacheResponse, ComplexOrdersRequest, ComplexOrdersResponse,
    GetUserRequest, HealthRequest, HealthResponse, JsonItem, JsonItemsRequest,
    JsonItemsResponse, UserOrderStats, UserResponse,
};

pub struct BenchmarkServiceImpl {
    db: DbPool,
    cache: CacheClient,
}

impl BenchmarkServiceImpl {
    pub fn new(db: DbPool, cache: CacheClient) -> BenchmarkServiceServer<Self> {
        BenchmarkServiceServer::new(Self { db, cache })
    }
}

// The generated trait uses native async fn in trait (RPITIT); no macro needed.
impl BenchmarkService for BenchmarkServiceImpl {
    async fn health(
        &self,
        _request: Request<HealthRequest>,
    ) -> Result<Response<HealthResponse>, Status> {
        let db_status = match self.db.client.query_one("SELECT 1", &[]).await {
            Ok(_) => "connected".to_string(),
            Err(e) => format!("error: {}", e),
        };

        let cache_status: String = {
            let mut conn = self.cache.conn.clone();
            match redis::cmd("PING").query_async::<String>(&mut conn).await {
                Ok(_) => "connected".to_string(),
                Err(e) => format!("error: {}", e),
            }
        };

        Ok(Response::new(HealthResponse {
            status: "ok".to_string().into(),
            version: env!("CARGO_PKG_VERSION").to_string().into(),
            timestamp: Utc::now().to_rfc3339().into(),
            database: db_status.into(),
            cache: cache_status.into(),
        }))
    }

    async fn get_json_items(
        &self,
        request: Request<JsonItemsRequest>,
    ) -> Result<Response<JsonItemsResponse>, Status> {
        let limit = request.into_inner().limit;
        let count = crate::canonical::item_count(limit);
        // The previous version minted a Uuid::new_v4() per item -- 1000 random
        // UUIDs per request -- and formatted Utc::now() into every created_at.
        // See contracts/rest/canonical-payloads.md.

        let items: Vec<JsonItem> = (0..count)
            .map(|i| JsonItem {
                id: i,
                uuid: crate::canonical::uuid(i).into(),
                name: crate::canonical::name(i).into(),
                email: crate::canonical::email(i).into(),
                created_at: crate::canonical::CANONICAL_CREATED_AT.to_string().into(),
                is_active: crate::canonical::is_active(i),
            })
            .collect();

        Ok(Response::new(JsonItemsResponse {
            count: items.len() as i32,
            items,
            timestamp: Utc::now().to_rfc3339().into(),
        }))
    }

    async fn get_user(
        &self,
        request: Request<GetUserRequest>,
    ) -> Result<Response<UserResponse>, Status> {
        let id = request.into_inner().id;

        let row = self
            .db
            .client
            .query_one(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
                &[&id],
            )
            .await
            .map_err(|e| Status::not_found(format!("User not found: {}", e)))?;

        let created_at: std::time::SystemTime = row.get(5);
        let created_at: chrono::DateTime<Utc> = created_at.into();

        // The generated string fields are FastStr; read text columns as String
        // (FastStr does not implement tokio_postgres::FromSql) then convert.
        let email: String = row.get(1);
        let first_name: String = row.get(2);
        let last_name: String = row.get(3);

        Ok(Response::new(UserResponse {
            id: row.get(0),
            email: email.into(),
            first_name: first_name.into(),
            last_name: last_name.into(),
            age: row.get(4),
            created_at: created_at.to_rfc3339().into(),
        }))
    }

    async fn get_complex_orders(
        &self,
        request: Request<ComplexOrdersRequest>,
    ) -> Result<Response<ComplexOrdersResponse>, Status> {
        let days = request.into_inner().days;
        let days = if days > 0 { days } else { 30 };

        let rows = self
            .db
            .client
            .query(
                "SELECT u.id, u.first_name || ' ' || u.last_name AS user_name, \
                 COUNT(o.id) AS total_orders, \
                 COALESCE(SUM(o.total_amount), 0) AS total_value, \
                 COALESCE(AVG(o.total_amount), 0) AS average_order_value \
                 FROM users u \
                 LEFT JOIN orders o ON o.user_id = u.id \
                   AND o.created_at >= NOW() - ($1 || ' days')::interval \
                 GROUP BY u.id, user_name \
                 ORDER BY total_value DESC \
                 LIMIT 100",
                &[&days],
            )
            .await
            .map_err(|e| Status::internal(format!("Query error: {}", e)))?;

        let data: Vec<UserOrderStats> = rows
            .iter()
            .map(|row| {
                let user_name: String = row.get(1);
                UserOrderStats {
                    user_id: row.get(0),
                    user_name: user_name.into(),
                    total_orders: row.get(2),
                    total_value: row.get::<_, f64>(3),
                    average_order_value: row.get::<_, f64>(4),
                }
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
        let cache_key = format!("benchmark:{}", key);
        let mut conn = self.cache.conn.clone();

        // Try cache hit first
        let cached: Option<String> = conn
            .get(&cache_key)
            .await
            .map_err(|e| Status::internal(format!("Redis error: {}", e)))?;

        if let Some(value) = cached {
            let ttl: i32 = conn.ttl(&cache_key).await.unwrap_or(-1);

            return Ok(Response::new(CacheResponse {
                key: key.into(),
                value: value.into(),
                cached: true,
                ttl,
                timestamp: Utc::now().to_rfc3339().into(),
            }));
        }

        // Cache miss: generate value and store
        let value = format!("value_{}", Uuid::new_v4());
        let _: () = conn
            .set_ex(&cache_key, &value, 3600)
            .await
            .map_err(|e| Status::internal(format!("Redis error: {}", e)))?;

        Ok(Response::new(CacheResponse {
            key: key.into(),
            value: value.into(),
            cached: false,
            ttl: 3600,
            timestamp: Utc::now().to_rfc3339().into(),
        }))
    }
}
