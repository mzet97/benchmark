# Rust Axum Benchmark Implementation

High-performance REST API benchmark using Rust with Axum framework.

## Features

- **Framework**: Axum 0.7
- **Database**: PostgreSQL with sqlx
- **Cache**: Redis
- **Async Runtime**: Tokio
- **Performance**: Native binary compilation

## Endpoints

1. `GET /health` - Health check
2. `GET /json` - JSON serialization (1000 objects)
3. `GET /db/simple?id=1` - Simple database query
4. `GET /db/complex?days=30` - Complex database query with aggregation
5. `GET /cache?key=test` - Cache operations

## Build

```bash
# Local development
./build.sh local

# Docker image
./build.sh docker

# Run tests
./build.sh test

# Code format check
./build.sh check

# Format code
./build.sh fmt
```

## Run

```bash
# Docker container
./run.sh

# Direct binary
./target/release/benchmark-axum
```

## Kubernetes

```bash
kubectl apply -f k8s/
```

## Performance

Expected throughput: 500k+ req/sec
