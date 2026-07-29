mod cache;
mod db;
mod service;

use service::BenchmarkServiceImpl;
use tokio::signal;
use volo_grpc::server::{Server, ServiceBuilder};

#[volo::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/benchmark".to_string());
    let redis_url =
        std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string());

    let db_pool = db::connect(&database_url).await?;
    let cache_client = cache::connect(&redis_url).await?;

    let addr = "0.0.0.0:50051".parse::<std::net::SocketAddr>()?;
    let svc = BenchmarkServiceImpl::new(db_pool, cache_client);

    println!("Volo gRPC server listening on {}", addr);

    Server::new()
        .add_service(svc)
        .run(addr)
        .await?;

    Ok(())
}
