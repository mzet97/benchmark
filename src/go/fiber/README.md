# Go Fiber - Benchmark API

High-performance REST API implementation using Go 1.23 and Fiber web framework.

## 🚀 Features

- **Framework**: Fiber v2 (Express.js-inspired)
- **Go Version**: 1.23 (latest)
- **Database**: PostgreSQL with pgx driver
- **Cache**: Redis with go-redis/v9
- **Performance**: Zero allocations, low latency
- **Concurrency**: Goroutines, channels

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

### Prerequisites

```bash
# Go 1.23+
go version

# Docker (optional)
docker --version
```

### Local Development

```bash
# Build and run
./build.sh local
./run.sh dev
```

### Docker Build

```bash
# Build image
./build.sh docker

# Run container
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://..." \
  -e REDIS_URL="redis://..." \
  benchmark/go-fiber:latest
```

### Environment Variables

```bash
PORT=8080
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://user:pass@host:6379
```

## 🧪 Testing

```bash
# Run tests
./build.sh test

# Run tests with coverage
./build.sh test-coverage

# Format code
./build.sh fmt

# Vet code
./build.sh vet
```

## 📊 Performance

### Expected Characteristics
- **Startup Time**: < 10ms
- **Memory Footprint**: 10-20 MB
- **Throughput**: 500k+ req/sec
- **Latency**: < 1ms p99
- **Concurrency**: Goroutines with minimal overhead

### Go Advantages
- **Fast Compilation**: Seconds to build
- **Static Binary**: No runtime dependencies
- **Low Memory**: Efficient garbage collection
- **High Concurrency**: Goroutines scale well

## 🔧 Configuration

### Database Connection
```go
// Using pgx
conn, err := pgx.Connect(context.Background(), dbURL)
```

### Redis Connection
```go
// Using go-redis/v9
client := redis.NewClient(&redis.Options{
    Addr:     "host:6379",
    Password: "password",
})
```

## 📦 Dependencies

### Core
- `github.com/gofiber/fiber/v2` - Web framework
- `github.com/gofiber/fiber/v2/middleware/*` - Middleware

### Database
- `github.com/jackc/pgx/v5` - PostgreSQL driver
- `github.com/redis/go-redis/v9` - Redis client

### Utilities
- `github.com/rs/zerolog` - Structured logging
- `github.com/goccy/go-json` - Fast JSON
- `github.com/google/uuid` - UUID generation

## 🐳 Kubernetes

Deploy with:
```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Port-forward:
```bash
kubectl port-forward svc/go-fiber 8080:80
```

## 📈 Benchmarking

```bash
# Using wrk
wrk -t8 -c200 -d30s --latency http://localhost:8080/health

# Using k6
k6 run scripts/k6-test.js
```

## 📁 Project Structure

```
src/go/fiber/
├── go.mod                               # Go modules
├── Dockerfile                            # Multi-stage build
├── docker-compose.yml                   # Local orchestration
├── build.sh                             # Build automation
├── run.sh                               # Run automation
├── .env.example                         # Environment template
├── .gitignore                           # Git ignore rules
├── README.md                            # This file
├── cmd/server/
│   └── main.go                          # Application entry point
├── internal/
│   ├── models/                          # Data models
│   ├── services/                        # Business logic
│   └── handlers/                        # HTTP handlers
└── k8s/
    ├── deployment.yaml                  # K8s deployment
    ├── service.yaml                     # K8s service
    └── configmap.yaml                   # K8s config
```

## 🎯 Endpoints Summary

| Endpoint | Method | Description | DB Query |
|----------|--------|-------------|----------|
| `/health` | GET | Health check | SELECT 1 |
| `/json` | GET | 1000 JSON objects | None |
| `/db/simple?id={id}` | GET | User by ID | Simple SELECT |
| `/db/complex?days={n}` | GET | User order stats | JOIN + Aggregation |
| `/cache?key={k}` | GET | Cache GET/SET | Redis |

## 🛠️ Development

### Build Options
```bash
./build.sh {local|docker|clean|test|test-coverage|vet|fmt|mod-tidy}
```

### Run Modes
```bash
./run.sh {dev|prod|docker|race}
```

### Debug
```bash
# Run with race detector
./run.sh race

# View coverage
open coverage.html
```

## 📈 Expected Performance

Based on Go and Fiber benchmarks:
- **Throughput**: 500k+ req/sec
- **Latency**: < 1ms p99
- **Memory**: 10-20 MB
- **Startup**: < 10ms
- **CPU**: Low overhead

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
# Test PostgreSQL
psql "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"

# Test Redis
redis-cli -h redis.home.arpa -p 30379 -a Admin@123 PING
```

### Port Already in Use
```bash
# Find process using port 8080
lsof -i :8080

# Kill process
kill -9 <PID>
```

## 📚 Documentation

- [Fiber Guide](https://docs.gofiber.io/)
- [Go PostgreSQL Driver](https://pkg.go.dev/github.com/jackc/pgx/v5)
- [Redis Go Client](https://pkg.go.dev/github.com/redis/go-redis/v9)
- [Go Concurrency](https://go.dev/doc/effective_go#concurrency)

## 📝 License

MIT

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/go-fiber:latest`
**Performance**: ⭐⭐⭐⭐⭐ Excellent
