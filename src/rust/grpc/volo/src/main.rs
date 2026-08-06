mod canonical;
mod cache;
mod db;
mod service;

use service::{
    BenchmarkServiceImpl, BenchmarkServiceRequestRecv, BenchmarkServiceResponseSend,
};
use volo::net::Address;
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

    // ServiceBuilder wraps the generated service and build() produces a
    // CodecService that operates on BoxBody, which is what add_service requires.
    let codec_svc = ServiceBuilder::new(svc)
        .build::<BenchmarkServiceRequestRecv, BenchmarkServiceResponseSend>();

    Server::new()
        .add_service(codec_svc)
        .run(Address::Ip(addr))
        .await?;

    Ok(())
}
