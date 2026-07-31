# 🚀 Go Fiber - Quick Reference

## ⚡ Build & Deploy (1 comando)

```bash
cd src/go/fiber
./build.sh docker
```

## 🏃‍♂️ Run Locally

### Development
```bash
cd src/go/fiber
./build.sh local
./run.sh dev
```

### With Race Detector
```bash
./build.sh build-race
./run.sh race
```

## 📋 Build Options

```bash
./build.sh {local|docker|clean|test|test-coverage|vet|fmt|mod-tidy|docker-push}
```

- **local**: Build binary for local development
- **docker**: Build Docker image
- **clean**: Clean build artifacts
- **test**: Run tests
- **test-coverage**: Run tests with coverage
- **vet**: Run go vet linter
- **fmt**: Format code
- **mod-tidy**: Tidy go modules
- **docker-push**: Push to registry
- **build-race**: Build with race detector

## 🐳 Docker

### Build
```bash
docker build -t benchmark/go-fiber:latest src/go/fiber
```

### Run
```bash
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://..." \
  -e REDIS_URL="redis://..." \
  benchmark/go-fiber:latest
```

### Docker Compose
```bash
cd src/go/fiber
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
kubectl apply -f src/go/fiber/k8s/configmap.yaml -n benchmark
kubectl apply -f src/go/fiber/k8s/deployment.yaml -n benchmark
kubectl apply -f src/go/fiber/k8s/service.yaml -n benchmark

# Wait for pods
kubectl wait --for=condition=ready pod -l app=go-fiber --timeout=120s -n benchmark

# Port-forward
kubectl port-forward -n benchmark svc/go-fiber 8080:80
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
./scripts/benchmark-wrk-go.sh benchmark

# View results
cat /tmp/benchmark-go-report.md
```

## 📊 Performance Features

- **Fiber Web Framework**: Express.js-inspired, fast routing
- **Goroutines**: Lightweight threads (2KB stack)
- **Zero Allocations**: Minimal garbage collection pressure
- **Static Binary**: No runtime dependencies
- **Low Latency**: Sub-millisecond response times

## 🔧 Configuration

### Environment Variables
```bash
PORT=8080
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://user:pass@host:6379
```

### Go Environment
```bash
export CGO_ENABLED=0  # For static linking
export GIN_MODE=debug # or release
```

## 📁 Project Structure

```
src/go/fiber/
├── go.mod                     # Go modules (dependencies)
├── Dockerfile                 # Multi-stage build
├── docker-compose.yml         # Local orchestration
├── build.sh                   # Build automation
├── run.sh                     # Run automation
├── .env.example               # Environment template
├── .gitignore                 # Git ignore rules
├── cmd/server/
│   └── main.go               # Application entry point
├── internal/
│   ├── models/               # Data models (User, Order, etc.)
│   ├── services/             # Database + Cache services
│   └── handlers/             # HTTP handlers (endpoints)
└── k8s/
    ├── deployment.yaml       # K8s deployment
    ├── service.yaml          # K8s service
    └── configmap.yaml        # K8s config
```

## 🎯 Endpoints Summary

| Endpoint | Method | Description | DB Query |
|----------|--------|-------------|----------|
| `/health` | GET | Health check | SELECT 1 (PostgreSQL + Redis) |
| `/json` | GET | 1000 JSON objects | None |
| `/db/simple?id={id}` | GET | User by ID | Simple SELECT |
| `/db/complex?days={n}` | GET | User order stats | JOIN + Aggregation |
| `/cache?key={k}` | GET | Cache GET/SET (TTL 300s) | Redis |

## 🛠️ Development

### Prerequisites
```bash
# Go 1.23+
go version

# Git (for go modules)
git --version
```

### Build & Run Cycle
```bash
# Build
./build.sh local

# Run
./run.sh dev

# Test
./build.sh test

# Format
./build.sh fmt
```

### Debug Mode
```bash
# With race detector
./run.sh race

# View test coverage
./build.sh test-coverage
open coverage.html
```

## 📈 Expected Performance

Based on Go benchmarks:
- **Startup**: < 10ms (fastest among all languages)
- **Memory**: 10-20 MB (very efficient)
- **Throughput**: 500k+ req/sec (excellent)
- **Latency**: < 1ms p99 (sub-millisecond)
- **CPU**: Minimal overhead (goroutines)

### Go Advantages
1. **Fast Compilation**: Build in seconds
2. **Static Binary**: Self-contained executable
3. **Simple**: Easy to learn and read
4. **Concurrent**: Goroutines scale naturally
5. **Garbage Collected**: No manual memory management

## ❌ Troubleshooting

### Build Errors
```bash
# Clean and rebuild
./build.sh clean
./build.sh local

# Check Go version
go version
```

### Connection Errors
```bash
# Check PostgreSQL
psql "postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api"

# Check Redis
redis-cli -h redis.home.arpa -p 30379 -a <REDACTED> PING
```

### Port Already in Use
```bash
# Find process
lsof -i :8080

# Kill process
kill -9 <PID>
```

## 📚 Documentation

- [Fiber Web Framework](https://docs.gofiber.io/)
- [Go PostgreSQL Driver (pgx)](https://pkg.go.dev/github.com/jackc/pgx/v5)
- [Redis Go Client](https://pkg.go.dev/github.com/redis/go-redis/v9)
- [Go Official Docs](https://go.dev/doc/)
- [Goroutines](https://go.dev/doc/effective_go#concurrency)

## 🔄 Go Commands

```bash
# Build
go build -o ./bin/server ./cmd/server/main.go

# Run
go run ./cmd/server/main.go

# Test
go test -v ./...

# Format
go fmt ./...

# Vet
go vet ./...

# Modules
go mod tidy
go mod download
```

## 📊 Comparison

| Feature | C# (.NET) | Rust | Java (Quarkus) | Go (Fiber) |
|---------|-----------|------|----------------|------------|
| Build Time | ~60-70s | ~120-180s | ~180-300s | ~5-10s |
| Binary Size | ~80-100 MB | ~15-20 MB | ~60-80 MB | ~15-25 MB |
| Memory Usage | ~50-80 MB | ~10-20 MB | ~20-40 MB | ~10-20 MB |
| Startup Time | ~50-100ms | ~10-50ms | <50ms | <10ms |
| Throughput | 400k+/s | 500k+/s | 400k-500k/s | 500k+/s |
| Latency | ~1-2ms | ~0.5-1ms | ~1-2ms | <1ms |
| Learning Curve | Medium | High | Medium | Low |
| Dev Speed | Good | Medium | Good | Excellent |

## 🎉 Key Advantages

1. **Blazing Fast**: Fastest compilation and startup
2. **Simple Syntax**: Easy to read and maintain
3. **Goroutines**: Lightweight concurrency
4. **Static Binary**: No runtime dependencies
5. **Great Tooling**: Built-in testing, profiling, formatting
6. **Production Ready**: Used by Google, Uber, Netflix

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/go-fiber:latest`
**Performance**: ⭐⭐⭐⭐⭐ Excellent
**Go Version**: 1.23
**Fiber Version**: 2.52
