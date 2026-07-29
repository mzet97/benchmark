mod cache;
mod db;
mod service;

use service::BenchmarkServiceImpl;
use tokio::signal;
use tonic::transport::Server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let database_url =
        std::env::var("DATABASE_URL").unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/benchmark".to_string());
    let redis_url =
        std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string());

    let db_pool = db::connect(&database_url).await?;
    let cache_client = cache::connect(&redis_url).await?;

    let addr = "0.0.0.0:50051".parse()?;
    let svc = BenchmarkServiceImpl::new(db_pool, cache_client);

    println!("gRPC server listening on {}", addr);

    Server::builder()
        .add_service(svc)
        .serve_with_shutdown(addr, async {
            signal::ctrl_c()
                .await
                .expect("failed to listen for Ctrl+C");
            println!("Shutting down gracefully...");
        })
        .await?;

    Ok(())
}
