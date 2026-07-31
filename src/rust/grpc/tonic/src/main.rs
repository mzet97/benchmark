mod cache;
mod db;
mod service;

use service::BenchmarkServiceImpl;
use tokio::signal;
use tonic::transport::Server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let database_url =
        env::var("DATABASE_URL").expect("DATABASE_URL is required");
    let redis_url =
        std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://10.43.190.124:6379".to_string());

    println!("Connecting to database...");
    let db_pool = match db::connect(&database_url).await {
        Ok(pool) => {
            println!("Database connected successfully");
            Some(pool)
        }
        Err(e) => {
            eprintln!("Warning: Database connection failed: {}. Running without DB.", e);
            None
        }
    };

    println!("Connecting to cache...");
    let cache_client = match cache::connect(&redis_url).await {
        Ok(client) => {
            println!("Cache connected successfully");
            Some(client)
        }
        Err(e) => {
            eprintln!("Warning: Cache connection failed: {}. Running without cache.", e);
            None
        }
    };

    let addr = "0.0.0.0:50051".parse()?;
    let svc = BenchmarkServiceImpl::new(db_pool, cache_client);

    println!("gRPC server listening on {}", addr);

    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(service::benchmark::FILE_DESCRIPTOR_SET)
        .build_v1()
        .unwrap_or_else(|e| {
            eprintln!("Warning: Reflection service failed to build: {}", e);
            tonic_reflection::server::Builder::configure().build_v1().unwrap()
        });

    Server::builder()
        .add_service(svc)
        .add_service(reflection_service)
        .serve_with_shutdown(addr, async {
            signal::ctrl_c()
                .await
                .expect("failed to listen for Ctrl+C");
            println!("Shutting down gracefully...");
        })
        .await?;

    Ok(())
}
