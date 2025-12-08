# Rust Actix Web - Benchmark API

High-performance REST API implementation using Rust and Actix Web.

## 🚀 Features

- **Framework**: Actix Web 4.x
- **Database**: PostgreSQL with bb8 connection pool
- **Cache**: Redis with tokio support
- **Async**: Full async/await support
- **Performance**: Zero-cost abstractions, minimal overhead

## 📋 Endpoints

1. **GET /health** - Health check
   - Returns: Database and Redis connectivity status

2. **GET /json** - JSON response
   - Returns: 1000 JSON objects

3. **GET /db/simple?id={id}** - Simple database query
   - Returns: User by ID

4. **GET /db/complex?days={days}** - Complex database query
   - Returns: Aggregated order statistics

5. **GET /cache?key={key}** - Cache operations
   - Returns: Cached value or generates new one

## 🏗️ Build & Run

### Local Development

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build
cargo build --release

# Run
./target/release/benchmark-actix
```

### Docker Build

```bash
# Build image
docker build -t benchmark/rust-actix-web:latest .

# Run container
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://..." \
  -e REDIS_URL="redis://..." \
  benchmark/rust-actix-web:latest
```

### Environment Variables

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://user:pass@host:6379
SERVER_BIND=0.0.0.0:8080
SERVER_WORKERS=4
```

## 🧪 Testing

```bash
# Health check
curl http://localhost:8080/health

# JSON endpoint
curl http://localhost:8080/json

# Database queries
curl http://localhost:8080/db/simple?id=1
curl http://localhost:8080/db/complex?days=30

# Cache operations
curl http://localhost:8080/cache?key=test
```

## 📊 Performance

Rust with Actix Web provides:
- **High throughput** with minimal overhead
- **Low latency** with async/await
- **Memory efficient** with zero-copy operations
- **CPU optimized** with static dispatch

## 🔧 Configuration

### Connection Pooling
- PostgreSQL: 25 connections (default)
- Redis: Connection per request

### Worker Threads
- Default: 4 workers (or CPU cores)
- Configurable via `SERVER_WORKERS`

## 📦 Dependencies

- `actix-web`: Web framework
- `tokio-postgres`: PostgreSQL async driver
- `bb8`: Connection pool
- `redis`: Redis client
- `serde`: Serialization
- `chrono`: Date/time handling

## 🐳 Kubernetes

Deploy with:
```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Port-forward:
```bash
kubectl port-forward svc/rust-actix-web 8080:80
```

## 📈 Benchmarking

```bash
# Using wrk
wrk -t8 -c200 -d30s --latency http://localhost:8080/health

# Using k6
k6 run scripts/k6-test.js
```

## 📝 License

MIT
