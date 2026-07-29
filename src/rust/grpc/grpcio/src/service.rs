use crate::cache::CacheClient;
use crate::db::DbPool;
use chrono::Utc;
use futures::Future;
use grpcio::{RpcContext, RpcStatus, RpcStatusCode, UnarySink};
use redis::AsyncCommands;
use std::sync::Arc;
use uuid::Uuid;

// Include generated code
include!(concat!(env!("OUT_DIR"), "/benchmark.rs"));
include!(concat!(env!("OUT_DIR"), "/benchmark_grpc.rs"));

use self::benchmark::*;
use self::benchmark_grpc::*;

pub struct BenchmarkService {
    db: DbPool,
    cache: CacheClient,
}

impl BenchmarkService {
    pub fn new(db: DbPool, cache: CacheClient) -> BenchmarkServiceServer {
        let service = Arc::new(Self { db, cache });
        BenchmarkServiceServer::new(service)
    }
}

impl BenchmarkGrpc for BenchmarkService {
    fn health(
        &self,
        ctx: RpcContext,
        req: HealthRequest,
        sink: UnarySink<HealthResponse>,
    ) {
        let db = self.db.clone();
        let cache = self.cache.clone();

        let f = async move {
            let db_status = match db.client.query_one("SELECT 1", &[]).await {
                Ok(_) => "connected".to_string(),
                Err(e) => format!("error: {}", e),
            };

            let cache_status: String = {
                let mut conn = cache.conn.clone();
                match redis::cmd("PING").query_async::<String>(&mut conn).await {
                    Ok(_) => "connected".to_string(),
                    Err(e) => format!("error: {}", e),
                }
            };

            let mut resp = HealthResponse::default();
            resp.status = "ok".to_string();
            resp.version = env!("CARGO_PKG_VERSION").to_string();
            resp.timestamp = Utc::now().to_rfc3339();
            resp.database = db_status;
            resp.cache = cache_status;

            Ok(resp)
        };

        let f = f.map(move |r| match r {
            Ok(resp) => sink.success(resp),
            Err(e) => sink.fail(RpcStatus::with_message(
                RpcStatusCode::INTERNAL,
                format!("Health check error: {}", e),
            )),
        });
        ctx.spawn(f);
    }

    fn get_json_items(
        &self,
        ctx: RpcContext,
        req: JsonItemsRequest,
        sink: UnarySink<JsonItemsResponse>,
    ) {
        let limit = if req.limit > 0 { req.limit } else { 1000 };

        let items: Vec<JsonItem> = (0..limit)
            .map(|i| {
                let mut item = JsonItem::default();
                item.id = i;
                item.uuid = Uuid::new_v4().to_string();
                item.name = format!("Item {}", i);
                item.email = format!("item{}@example.com", i);
                item.created_at = Utc::now().to_rfc3339();
                item.is_active = i % 2 == 0;
                item
            })
            .collect();

        let mut resp = JsonItemsResponse::default();
        resp.count = items.len() as i32;
        resp.items = items.into();
        resp.timestamp = Utc::now().to_rfc3339();

        let f = futures::future::ok(resp);
        let f = f.map(move |r| match r {
            Ok(resp) => sink.success(resp),
            Err(e) => sink.fail(RpcStatus::with_message(
                RpcStatusCode::INTERNAL,
                format!("Error: {}", e),
            )),
        });
        ctx.spawn(f);
    }

    fn get_user(
        &self,
        ctx: RpcContext,
        req: GetUserRequest,
        sink: UnarySink<UserResponse>,
    ) {
        let db = self.db.clone();

        let f = async move {
            let row = db
                .client
                .query_one(
                    "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
                    &[&req.id],
                )
                .await
                .map_err(|e| format!("User not found: {}", e))?;

            let created_at: std::time::SystemTime = row.get(5);
            let created_at: chrono::DateTime<Utc> = created_at.into();

            let mut resp = UserResponse::default();
            resp.id = row.get(0);
            resp.email = row.get(1);
            resp.first_name = row.get(2);
            resp.last_name = row.get(3);
            resp.age = row.get(4);
            resp.created_at = created_at.to_rfc3339();

            Ok(resp)
        };

        let f = f.map(move |r: Result<UserResponse, String>| match r {
            Ok(resp) => sink.success(resp),
            Err(e) => sink.fail(RpcStatus::with_message(RpcStatusCode::NOT_FOUND, e)),
        });
        ctx.spawn(f);
    }

    fn get_complex_orders(
        &self,
        ctx: RpcContext,
        req: ComplexOrdersRequest,
        sink: UnarySink<ComplexOrdersResponse>,
    ) {
        let db = self.db.clone();
        let days = if req.days > 0 { req.days } else { 30 };

        let f = async move {
            let rows = db
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
                .map_err(|e| format!("Query error: {}", e))?;

            let data: Vec<UserOrderStats> = rows
                .iter()
                .map(|row| {
                    let mut stats = UserOrderStats::default();
                    stats.user_id = row.get(0);
                    stats.user_name = row.get(1);
                    stats.total_orders = row.get(2);
                    stats.total_value = row.get::<_, f64>(3);
                    stats.average_order_value = row.get::<_, f64>(4);
                    stats
                })
                .collect();

            let mut resp = ComplexOrdersResponse::default();
            resp.period_days = days;
            resp.total_users = data.len() as i32;
            resp.data = data.into();

            Ok(resp)
        };

        let f = f.map(move |r: Result<ComplexOrdersResponse, String>| match r {
            Ok(resp) => sink.success(resp),
            Err(e) => sink.fail(RpcStatus::with_message(RpcStatusCode::INTERNAL, e)),
        });
        ctx.spawn(f);
    }

    fn get_cache_value(
        &self,
        ctx: RpcContext,
        req: CacheRequest,
        sink: UnarySink<CacheResponse>,
    ) {
        let cache = self.cache.clone();
        let key = req.key.clone();

        let f = async move {
            let cache_key = format!("benchmark:{}", key);
            let mut conn = cache.conn.clone();

            // Try cache hit first
            let cached: Option<String> = conn
                .get(&cache_key)
                .await
                .map_err(|e| format!("Redis error: {}", e))?;

            if let Some(value) = cached {
                let ttl: i32 = conn.ttl(&cache_key).await.unwrap_or(-1);

                let mut resp = CacheResponse::default();
                resp.key = key;
                resp.value = value;
                resp.cached = true;
                resp.ttl = ttl;
                resp.timestamp = Utc::now().to_rfc3339();
                return Ok(resp);
            }

            // Cache miss: generate value and store
            let value = format!("value_{}", Uuid::new_v4());
            let _: () = conn
                .set_ex(&cache_key, &value, 3600)
                .await
                .map_err(|e| format!("Redis error: {}", e))?;

            let mut resp = CacheResponse::default();
            resp.key = key;
            resp.value = value;
            resp.cached = false;
            resp.ttl = 3600;
            resp.timestamp = Utc::now().to_rfc3339();

            Ok(resp)
        };

        let f = f.map(move |r: Result<CacheResponse, String>| match r {
            Ok(resp) => sink.success(resp),
            Err(e) => sink.fail(RpcStatus::with_message(RpcStatusCode::INTERNAL, e)),
        });
        ctx.spawn(f);
    }
}
