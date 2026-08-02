mod canonical;
mod cache;
mod db;
mod service;

use futures::prelude::*;
use grpcio::{Environment, RpcContext, Server, ServerBuilder};
use service::BenchmarkService;
use std::sync::Arc;
use tokio::signal;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/benchmark".to_string());
    let redis_url =
        std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string());

    let db_pool = db::connect(&database_url).await?;
    let cache_client = cache::connect(&redis_url).await?;

    let env = Arc::new(Environment::new(2));
    let service_instance = BenchmarkService::new(db_pool, cache_client);

    let mut server = ServerBuilder::new(env)
        .register_service(service_instance)
        .bind("0.0.0.0", 50051)
        .build()?;

    server.start();

    println!("grpcio gRPC server listening on 0.0.0.0:50051");

    // Wait for shutdown signal
    signal::ctrl_c().await.expect("failed to listen for Ctrl+C");
    println!("Shutting down grpcio gRPC server...");

    let _ = server.shutdown().await;

    Ok(())
}
