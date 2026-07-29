#!/usr/bin/env python3
"""Final fix for Rust implementations - write files, rebuild, deploy."""
import paramiko
import time

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = "Admin@123"

# Rocket main.rs - remove Shield, fix imports
ROCKET_MAIN = r"""#[macro_use]
extern crate rocket;

use rocket::{
    http::Status,
    serde::json::Json,
    State,
};
use serde::Serialize;
use chrono::Utc;

mod db;
mod cache;
mod handlers;

use db::Database;
use cache::Cache;

#[get("/")]
fn index() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "name": "Benchmark API - Rust Rocket",
        "version": "1.0.0",
        "description": "High-performance REST API benchmark",
        "runtime": "Rust",
        "framework": "Rocket",
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

#[get("/health")]
async fn health(db: &State<Database>, cache: &State<Cache>) -> Result<Json<serde_json::Value>, Status> {
    let db_healthy = db.health_check().await.is_ok();
    let cache_healthy = cache.ping().await.is_ok();
    let response = serde_json::json!({
        "status": if db_healthy && cache_healthy { "healthy" } else { "unhealthy" },
        "version": "1.0.0",
        "timestamp": Utc::now().to_rfc3339(),
        "database": if db_healthy { "healthy" } else { "unhealthy" },
        "cache": if cache_healthy { "healthy" } else { "unhealthy" },
    });
    if !db_healthy || !cache_healthy {
        return Err(Status::ServiceUnavailable);
    }
    Ok(Json(response))
}

#[get("/healthz")]
fn healthz() -> Json<serde_json::Value> {
    Json(serde_json::json!({ "status": "ok" }))
}

#[get("/json")]
fn json_endpoint() -> Json<serde_json::Value> {
    let mut items = Vec::new();
    for i in 0..1000 {
        items.push(serde_json::json!({
            "id": i,
            "uuid": uuid::Uuid::new_v4().to_string(),
            "name": format!("User {}", i),
            "email": format!("user{}@example.com", i),
            "createdAt": Utc::now().to_rfc3339(),
            "isActive": true
        }));
    }
    Json(serde_json::json!({
        "items": items,
        "count": items.len(),
        "timestamp": Utc::now().to_rfc3339()
    }))
}

#[get("/db/simple?<id>")]
async fn db_simple(db: &State<Database>, id: Option<i32>) -> Result<Json<serde_json::Value>, Status> {
    let id = id.unwrap_or(1);
    match db.get_user(id).await {
        Ok(Some(user)) => Ok(Json(serde_json::json!({"user": user, "timestamp": Utc::now().to_rfc3339()}))),
        Ok(None) => Err(Status::NotFound),
        Err(_) => Err(Status::InternalServerError),
    }
}

#[get("/db/complex?<days>")]
async fn db_complex(db: &State<Database>, days: Option<i32>) -> Result<Json<serde_json::Value>, Status> {
    let days = days.unwrap_or(30);
    if days <= 0 || days > 365 { return Err(Status::BadRequest); }
    match db.get_complex_query(days).await {
        Ok(results) => Ok(Json(serde_json::json!({"period_days": days, "total_users": results.len(), "data": results}))),
        Err(_) => Err(Status::InternalServerError),
    }
}

#[get("/cache?<key>")]
async fn cache_endpoint(cache: &State<Cache>, key: Option<String>) -> Result<Json<serde_json::Value>, Status> {
    let key = key.unwrap_or_else(|| "test".to_string());
    let new_value = format!("cached-value-{}", uuid::Uuid::new_v4());
    match cache.get_or_set(&key, &new_value, 300).await {
        Ok((value, source)) => Ok(Json(serde_json::json!({"key": key, "value": value, "source": source, "timestamp": Utc::now().to_rfc3339()}))),
        Err(_) => Err(Status::InternalServerError),
    }
}

#[launch]
async fn rocket() -> _ {
    dotenvy::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api".to_string());
    let redis_url = std::env::var("REDIS_URL")
        .unwrap_or_else(|_| "redis://:Admin@123@redis.home.arpa:30379".to_string());
    let database = Database::new(&database_url).await;
    let cache = Cache::new(&redis_url).await;
    rocket::build()
        .manage(database)
        .manage(cache)
        .mount("/", routes![index, health, healthz, json_endpoint, db_simple, db_complex, cache_endpoint])
}
"""

# Rocket db.rs - use connect_lazy, raw query_as
ROCKET_DB = r"""use sqlx::PgPool;
use anyhow::{Result, Context};
use serde::Serialize;

#[derive(Debug)]
pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new(database_url: &str) -> Self {
        let pool = PgPool::connect_lazy(database_url)
            .expect("Failed to create database pool");
        Self { pool }
    }

    pub async fn health_check(&self) -> Result<()> {
        sqlx::query("SELECT 1").fetch_one(&self.pool).await
            .map(|_| ()).context("Database health check failed")
    }

    pub async fn get_user(&self, id: i32) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1"
        ).bind(id).fetch_optional(&self.pool).await?;
        Ok(user)
    }

    pub async fn get_complex_query(&self, days: i32) -> Result<Vec<ComplexUserStats>> {
        let rows = sqlx::query_as::<_, ComplexUserStats>(
            "SELECT u.id as user_id, u.email as user_email, COUNT(DISTINCT o.id) as total_orders, COALESCE(SUM(o.total_amount), 0) as total_value, COALESCE(AVG(o.total_amount), 0) as average_value, EXTRACT(EPOCH FROM AGE(NOW(), MIN(o.created_at))) / 86400.0 as days_since_first_order FROM users u LEFT JOIN orders o ON u.id = o.user_id AND o.created_at >= NOW() - ($1 || ' days')::INTERVAL GROUP BY u.id, u.email HAVING COUNT(DISTINCT o.id) > 0 ORDER BY total_value DESC LIMIT 100"
        ).bind(days).fetch_all(&self.pool).await?;
        Ok(rows)
    }
}

#[derive(sqlx::FromRow, Debug, Clone, Serialize)]
pub struct User {
    pub id: i32,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub age: Option<i32>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(sqlx::FromRow, Debug, Clone, Serialize)]
pub struct ComplexUserStats {
    pub user_id: i32,
    pub user_email: String,
    pub total_orders: i64,
    pub total_value: f64,
    pub average_value: f64,
    pub days_since_first_order: f64,
}
"""

# Rocket cache.rs
ROCKET_CACHE = r"""use redis::Client as RedisClient;
use anyhow::Result;

#[derive(Debug)]
pub struct Cache {
    client: RedisClient,
}

impl Cache {
    pub async fn new(redis_url: &str) -> Self {
        let client = RedisClient::open(redis_url)
            .expect("Failed to create Redis client");
        Self { client }
    }

    pub async fn ping(&self) -> Result<()> {
        let mut conn = self.client.get_async_connection().await?;
        redis::cmd("PING").query_async::<_, String>(&mut conn).await?;
        Ok(())
    }

    pub async fn get_or_set(&self, key: &str, value: &str, ttl_seconds: usize) -> Result<(String, String)> {
        let mut conn = self.client.get_async_connection().await?;
        let existing: Option<String> = redis::cmd("GET").arg(key).query_async(&mut conn).await?;
        match existing {
            Some(v) => Ok((v, "cache".to_string())),
            None => {
                redis::cmd("SETEX").arg(key).arg(ttl_seconds).arg(value)
                    .query_async::<_, String>(&mut conn).await?;
                Ok((value.to_string(), "generated".to_string()))
            }
        }
    }
}
"""

# Axum services.rs with get_or_set
AXUM_SERVICES = r"""use sqlx::PgPool;
use redis::Client as RedisClient;
use anyhow::{Result, Context};
use std::env;
use serde::Serialize;

#[derive(Debug, Clone)]
pub struct DatabaseService {
    pool: PgPool,
}

impl DatabaseService {
    pub async fn new() -> Self {
        let database_url = env::var("DATABASE_URL")
            .unwrap_or_else(|_| "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api".to_string());
        let pool = PgPool::connect_lazy(&database_url)
            .expect("Failed to create database pool");
        Self { pool }
    }

    pub async fn health_check(&self) -> Result<()> {
        sqlx::query("SELECT 1").fetch_one(&self.pool).await
            .map(|_| ()).context("Database health check failed")
    }

    pub async fn get_user(&self, id: i32) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1"
        ).bind(id).fetch_optional(&self.pool).await?;
        Ok(user)
    }

    pub async fn get_complex_query(&self, days: i32) -> Result<Vec<ComplexUserStats>> {
        let rows = sqlx::query_as::<_, ComplexUserStats>(
            "SELECT u.id as user_id, u.email as user_email, COUNT(DISTINCT o.id) as total_orders, COALESCE(SUM(o.total_amount), 0) as total_value, COALESCE(AVG(o.total_amount), 0) as average_value, EXTRACT(EPOCH FROM AGE(NOW(), MIN(o.created_at))) / 86400.0 as days_since_first_order FROM users u LEFT JOIN orders o ON u.id = o.user_id AND o.created_at >= NOW() - make_interval(days => $1) GROUP BY u.id, u.email HAVING COUNT(DISTINCT o.id) > 0 ORDER BY total_value DESC LIMIT 100"
        ).bind(days).fetch_all(&self.pool).await?;
        Ok(rows)
    }
}

#[derive(Debug, Clone)]
pub struct CacheService {
    client: RedisClient,
}

impl CacheService {
    pub async fn new() -> Self {
        let redis_url = env::var("REDIS_URL")
            .unwrap_or_else(|_| "redis://:Admin@123@redis.home.arpa:30379".to_string());
        let client = RedisClient::open(redis_url)
            .expect("Failed to create Redis client");
        Self { client }
    }

    pub async fn ping(&self) -> Result<()> {
        let mut conn = self.client.get_async_connection().await?;
        redis::cmd("PING").query_async::<_, String>(&mut conn).await?;
        Ok(())
    }

    pub async fn get(&self, key: &str) -> Result<Option<String>> {
        let mut conn = self.client.get_async_connection().await?;
        let value: Option<String> = redis::cmd("GET").arg(key).query_async(&mut conn).await?;
        Ok(value)
    }

    pub async fn get_or_set(&self, key: &str, value: &str, ttl_seconds: usize) -> Result<(String, String)> {
        let mut conn = self.client.get_async_connection().await?;
        let existing: Option<String> = redis::cmd("GET").arg(key).query_async(&mut conn).await?;
        match existing {
            Some(v) => Ok((v, "cache".to_string())),
            None => {
                redis::cmd("SETEX").arg(key).arg(ttl_seconds).arg(value)
                    .query_async::<_, String>(&mut conn).await?;
                Ok((value.to_string(), "generated".to_string()))
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct User {
    pub id: i32,
    pub email: String,
    pub first_name: String,
    pub last_name: String,
    pub age: i32,
    pub created_at: chrono::NaiveDateTime,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct ComplexUserStats {
    pub user_id: i32,
    pub user_email: String,
    pub total_orders: i64,
    pub total_value: f64,
    pub average_value: f64,
    pub days_since_first_order: Option<f64>,
}
"""

AXUM_CARGO = r"""[package]
name = "benchmark-axum"
version = "1.0.0"
edition = "2021"
authors = ["Benchmark Team"]
description = "High-performance REST API benchmark using Rust with Axum framework"
license = "MIT"

[dependencies]
axum = { version = "0.7", features = ["macros"] }
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid"] }
redis = { version = "0.25", features = ["tokio-rustls-comp"] }
uuid = { version = "1.0", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
tower = { version = "0.4", features = ["util", "timeout", "load-shed", "limit"] }
tower-http = { version = "0.5", features = ["cors", "trace"] }
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["fmt", "json", "env-filter"] }
anyhow = "1.0"
thiserror = "1.0"
dotenvy = "0.15"

[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = "abort"
strip = true
"""

FILES = {
    "/home/k8s1/benchmark/src/rust/axum/Cargo.toml": AXUM_CARGO,
    "/home/k8s1/benchmark/src/rust/axum/src/services.rs": AXUM_SERVICES,
    "/home/k8s1/benchmark/src/rust/rocket/src/main.rs": ROCKET_MAIN,
    "/home/k8s1/benchmark/src/rust/rocket/src/db.rs": ROCKET_DB,
    "/home/k8s1/benchmark/src/rust/rocket/src/cache.rs": ROCKET_CACHE,
}


def run_cmd(client, cmd, timeout=120):
    print(f"  >> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    code = stdout.channel.recv_exit_status()
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    if out.strip():
        for line in out.strip().splitlines()[-10:]:
            print(f"     {line}")
    if err.strip():
        for line in err.strip().splitlines()[-10:]:
            print(f"     [stderr] {line}")
    return code, out, err


def main():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(SERVER, username=USER, password=PASSWORD, timeout=30)
    print("Connected.\n")

    sftp = client.open_sftp()

    # Write all fix files
    for path, content in FILES.items():
        with sftp.open(path, "w") as f:
            f.write(content)
        print(f"Wrote {path}")
    sftp.close()

    # Regenerate Cargo.lock for axum since Cargo.toml changed
    print("\n=== Regenerating axum Cargo.lock ===")
    run_cmd(client,
        "cd /home/k8s1/benchmark/src/rust/axum && rm -f Cargo.lock && docker run --rm -v $(pwd):/app -w /app rust:latest cargo generate-lockfile",
        timeout=180)

    # Verify axum build
    print("\n=== Verifying axum build ===")
    code, out, err = run_cmd(client,
        "docker run --rm -v /home/k8s1/benchmark/src/rust/axum:/app -w /app rust:latest cargo build --release 2>&1 | tail -5",
        timeout=300)
    if "error" in (out + err).lower():
        print("  BUILD STILL FAILING")
        # Show errors
        run_cmd(client,
            "docker run --rm -v /home/k8s1/benchmark/src/rust/axum:/app -w /app rust:latest cargo build --release 2>&1 | grep '^error'",
            timeout=300)
    else:
        print("  BUILD OK")

    # Verify rocket build
    print("\n=== Verifying rocket build ===")
    code, out, err = run_cmd(client,
        "docker run --rm -v /home/k8s1/benchmark/src/rust/rocket:/app -w /app rust:latest cargo build --release 2>&1 | tail -5",
        timeout=300)
    if "error" in (out + err).lower():
        print("  BUILD STILL FAILING")
        run_cmd(client,
            "docker run --rm -v /home/k8s1/benchmark/src/rust/rocket:/app -w /app rust:latest cargo build --release 2>&1 | grep '^error'",
            timeout=300)
    else:
        print("  BUILD OK")

    # Now rebuild Docker images and deploy for those that compiled
    for impl_id, impl_path in [("rust-rest-axum", "src/rust/axum"), ("rust-rest-rocket", "src/rust/rocket")]:
        base = f"/home/k8s1/benchmark/{impl_path}"
        print(f"\n{'='*60}")
        print(f"Building and deploying: {impl_id}")
        print(f"{'='*60}")

        # Docker build
        print(f"\n[Build] Docker build")
        code, out, err = run_cmd(client,
            f"cd {base} && docker build --no-cache -t benchmark/{impl_id}:latest .",
            timeout=600)
        if code != 0:
            print(f"  DOCKER BUILD FAILED")
            continue

        # Docker save
        print(f"\n[Save]")
        run_cmd(client, f"docker save benchmark/{impl_id}:latest -o /tmp/{impl_id}.tar", timeout=300)

        # K3s import
        print(f"\n[Import]")
        run_cmd(client, f'bash -c "echo {PASSWORD} | sudo -S k3s ctr images import /tmp/{impl_id}.tar"', timeout=300)
        run_cmd(client, f"rm -f /tmp/{impl_id}.tar", timeout=30)

        # kubectl apply
        print(f"\n[Deploy]")
        code, out, err = run_cmd(client,
            f"cd /home/k8s1/benchmark && kubectl apply -k deploy/k3s/overlays/rest/{impl_id}/",
            timeout=60)

        # Check pods
        time.sleep(15)
        print(f"\n[Check]")
        run_cmd(client, f"kubectl get pods -l app={impl_id} -n benchmark", timeout=15)

    # Final status of all 6
    print(f"\n{'='*60}")
    print("FINAL STATUS - All implementations")
    print(f"{'='*60}")
    for impl_id in ["rust-rest-actix-web", "rust-rest-axum", "rust-rest-rocket", "go-rest-fiber", "go-rest-gin", "go-rest-echo"]:
        run_cmd(client, f"kubectl get pods -l app={impl_id} -n benchmark --no-headers 2>&1", timeout=10)

    client.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
