# 🚀 Rust Actix Web - Quick Reference

## ⚡ Build & Deploy (1 comando)

```bash
cd src/rust/actix-web
./build.sh docker
```

## 🏃‍♂️ Run Locally

```bash
cd src/rust/actix-web
./build.sh local
./run.sh dev
```

## 📋 Build Options

```bash
./build.sh {local|docker|clean|test|check|fmt}
```

- **local**: Build release binary (`./target/release/benchmark-actix`)
- **docker**: Build Docker image (`benchmark/rust-actix-web:latest`)
- **clean**: Clean build artifacts
- **test**: Run tests
- **check**: Run clippy lints
- **fmt**: Format code

## 🐳 Docker

### Build
```bash
docker build -t benchmark/rust-actix-web:latest src/rust/actix-web
```

### Run
```bash
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:${REDIS_PASSWORD}@redis.home.arpa:30379" \
  benchmark/rust-actix-web:latest
```

### Docker Compose
```bash
cd src/rust/actix-web
docker-compose up -d
```

## 🔍 Test Endpoints

```bash
# Health check
curl http://localhost:8080/health

# JSON response
curl http://localhost:8080/json

# Simple DB query
curl http://localhost:8080/db/simple?id=1

# Complex DB query
curl http://localhost:8080/db/complex?days=30

# Cache operations
curl http://localhost:8080/cache?key=test
```

## ⚖️ Kubernetes Deploy

```bash
# Deploy to Kubernetes
kubectl apply -f src/rust/actix-web/k8s/configmap.yaml -n benchmark
kubectl apply -f src/rust/actix-web/k8s/deployment.yaml -n benchmark
kubectl apply -f src/rust/actix-web/k8s/service.yaml -n benchmark

# Wait for pods
kubectl wait --for=condition=ready pod -l app=rust-actix-web --timeout=120s -n benchmark

# Port-forward
kubectl port-forward -n benchmark svc/rust-actix-web 8080:80
```

## 🧪 Benchmark

### Quick Test
```bash
# wrk (8 threads, 200 connections, 30s)
wrk -t8 -c200 -d30s --latency http://localhost:8080/health

# k6
k6 run scripts/k6-benchmark.js
```

### Automated Benchmark
```bash
# Full benchmark suite
./scripts/benchmark-wrk-rust.sh benchmark

# View results
cat /tmp/benchmark-rust-report.md
```

## 📊 Performance Features

- **Actix Web**: High-performance async web framework
- **Tokio**: Async runtime for Rust
- **bb8**: PostgreSQL connection pooling (25 connections)
- **Zero-cost abstractions**: Minimal runtime overhead
- **Memory efficient**: Stack-allocated data when possible
- **CPU optimized**: Compiled to native machine code

## 🔧 Configuration

### Environment Variables
```bash
DATABASE_URL=postgresql://app:pass@host:5432/benchmark_api
REDIS_URL=redis://:pass@host:6379
SERVER_BIND=0.0.0.0:8080
SERVER_WORKERS=4
```

### Config File
```bash
# config/default.toml
[database]
url = "postgresql://..."

[redis]
url = "redis://..."

[server]
bind = "0.0.0.0:8080"
workers = 4
```

## 📁 Project Structure

```
src/rust/actix-web/
├── Cargo.toml              # Dependencies
├── src/
│   ├── main.rs            # Application entry point
│   ├── models.rs          # Data models
│   └── services/
│       ├── database.rs    # PostgreSQL service
│       └── cache.rs       # Redis service
├── Dockerfile             # Multi-stage build
├── build.sh              # Build script
├── run.sh                # Run script
├── tests/
│   └── integration_test.rs # Tests
├── k8s/
│   ├── deployment.yaml   # K8s deployment
│   ├── service.yaml      # K8s service
│   └── configmap.yaml    # K8s config
└── README.md             # This file
```

## 🎯 Endpoints Summary

| Endpoint | Method | Description | DB Query |
|----------|--------|-------------|----------|
| `/health` | GET | Health check | None |
| `/json` | GET | 1000 JSON objects | None |
| `/db/simple?id={id}` | GET | User by ID | Simple SELECT |
| `/db/complex?days={n}` | GET | User order stats | JOIN + Aggregation |
| `/cache?key={k}` | GET | Cache GET/SET | Redis |

## 🛠️ Development

### Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### Add Dependencies
```bash
cargo add actix-web
cargo add tokio-postgres
cargo add bb8
cargo add redis
```

### Run Tests
```bash
cargo test
cargo test --release
```

### Lint & Format
```bash
cargo clippy
cargo fmt
```

## 📈 Expected Performance

Based on TechEmpower benchmarks, Actix Web typically achieves:
- **Throughput**: 500k+ req/sec (simple endpoints)
- **Latency**: < 1ms p99 (cached endpoints)
- **Memory**: ~10-20 MB footprint
- **CPU**: High efficiency with async I/O

## ❌ Troubleshooting

### Build Errors
```bash
# Install missing dependencies
sudo apt-get install pkg-config libssl-dev

# Update Rust
rustup update
```

### Connection Errors
```bash
# Check PostgreSQL
psql "postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api"

# Check Redis
redis-cli -h redis.home.arpa -p 30379 -a <REDACTED>
```

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>
```

## 📚 Documentation

- [Actix Web Guide](https://actix.rs/book/actix-web/)
- [Tokio Tutorial](https://tokio.rs/tokio/tutorial)
- [Rust PostgreSQL Client](https://docs.rs/tokio-postgres/)
- [Redis Rust Client](https://docs.rs/redis/)

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/rust-actix-web:latest`
**Performance**: ⭐⭐⭐⭐⭐ Excellent
