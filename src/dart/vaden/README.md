# Dart Shelf Benchmark Implementation

High-performance REST API implementation using **Dart 3.x** with **Shelf framework** - leveraging Dart's isolates for concurrent, high-performance server-side applications.

## Overview

This implementation provides a complete benchmark-ready REST API leveraging Dart's modern language features, isolates for concurrency, and Shelf's lightweight web framework.

### Key Technologies

- **Language**: Dart 3.x (sound null safety, records, patterns)
- **Framework**: Shelf + shelf_router (lightweight HTTP server framework)
- **Database**: PostgreSQL with postgres driver
- **Cache**: Redis with redis client
- **Type Safety**: Strong static typing with null safety
- **Concurrency**: Isolates (lightweight threads)
- **JSON**: Code generation with json_serializable

## Architecture

### Project Structure

```
src/dart/vaden/
+-- bin/
|   +-- server.dart              # Main entry point
+-- lib/
|   +-- server.dart              # Server configuration
|   +-- models/                  # Data models
|   |   +-- models.dart
|   |   +-- user.dart
|   |   +-- order.dart
|   |   +-- complex_order_result.dart
|   |   +-- json_item.dart
|   |   +-- health_status.dart
|   |   +-- cache_response.dart
|   +-- services/                # Business logic layer
|   |   +-- services.dart
|   |   +-- database_service.dart
|   |   +-- cache_service.dart
|   +-- routes/                  # API route handlers
|   |   +-- routes.dart
|   |   +-- health_routes.dart
|   |   +-- json_routes.dart
|   |   +-- database_routes.dart
|   |   +-- cache_routes.dart
|   +-- middleware/              # HTTP middleware
|   |   +-- middleware.dart
|   +-- utils/                   # Utilities
|       +-- logger.dart
+-- Dockerfile                   # Multi-stage Docker build
+-- build.sh                     # Build automation script
+-- run.sh                       # Run automation script
+-- pubspec.yaml                 # Dart dependencies
+-- analysis_options.yaml        # Linting configuration
+-- k8s/
    +-- deployment.yaml          # Kubernetes deployment
    +-- service.yaml             # Kubernetes service
    +-- configmap.yaml           # Configuration
```

### Design Patterns

- **Clean Architecture**: Clear separation of concerns
- **Type Safety**: Sound null safety with @JsonSerializable
- **Middleware Stack**: CORS, logging, error handling
- **Router-based**: shelf_router for declarative routing
- **Connection Management**: PostgreSQL and Redis connections
- **Graceful Shutdown**: Signal handling for clean exit

## Endpoints

### 1. Health Check
```http
GET /health
```
Returns API health status with database and cache connectivity checks.

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-12-07T10:30:00.000Z",
  "database": "healthy",
  "cache": "healthy"
}
```

### 2. JSON Response
```http
GET /json
```
Returns 1000 JSON objects for serialization benchmark.

### 3. Simple Database Query
```http
GET /db/simple?id={id}
```
Fetches a single user by ID from PostgreSQL.

**Parameters:**
- `id` (integer, required): User ID

### 4. Complex Database Query
```http
GET /db/complex?days={days}
```
Performs JOIN query with aggregation over specified days.

**Parameters:**
- `days` (integer, optional, default: 30): Number of days to look back

### 5. Cache Operations
```http
GET /cache?key={key}
```
Performs Redis cache GET/SET operations with TTL.

**Parameters:**
- `key` (string, required): Cache key

## Development

### Prerequisites

- Dart 3.x SDK
- PostgreSQL database
- Redis server
- Docker (optional)
- Kubernetes (optional)

### Local Setup

1. **Install Dart**
```bash
# Using snap (Linux)
sudo snap install dart --classic

# Using homebrew (macOS)
brew install dart

# Using chocolatey (Windows)
choco install dart-sdk
```

2. **Verify Installation**
```bash
dart --version
```

3. **Get Dependencies**
```bash
cd src/dart/vaden
dart pub get
```

4. **Generate Code**
```bash
dart run build_runner build --delete-conflicting-outputs
```

5. **Configure Environment**
```bash
cp .env.example .env
# Edit .env with your database credentials
```

6. **Run Development Server**
```bash
dart run bin/server.dart
```

7. **Run with Hot Reload**
```bash
dart run --observe bin/server.dart
```

## Docker

### Build Image
```bash
./build.sh
```

### Run Container
```bash
./run.sh
```

### Manual Docker Commands
```bash
# Build
docker build -t benchmark/dart-shelf:latest .

# Run
docker run -d \
  --name dart-shelf-app \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:${REDIS_PASSWORD}@redis.home.arpa:30379" \
  benchmark/dart-shelf:latest

# Logs
docker logs -f dart-shelf-app

# Stop
docker stop dart-shelf-app
```

## Kubernetes

### Deploy to K8s

```bash
# Apply manifests
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify deployment
kubectl get deployments
kubectl get pods -l app=dart-shelf

# Get service info
kubectl get svc dart-shelf

# View logs
kubectl logs -l app=dart-shelf -f
```

### Access the API

```bash
# Port forward (development)
kubectl port-forward svc/dart-shelf 3000:80

# Service endpoint (cluster)
dart-shelf.default.svc.cluster.local
```

## Performance Features

### Dart Runtime Advantages
- **JIT + AOT**: Development speed + Production performance
- **Isolates**: Lightweight threads for concurrency
- **Strong typing**: Sound null safety
- **Modern GC**: Generational garbage collector
- **Zero-cost abstractions**: Efficient code generation

### Shelf Framework
- **Lightweight**: Minimal overhead HTTP server
- **Composable**: Middleware-based architecture
- **Router-based**: Declarative route definitions
- **Standards-compliant**: HTTP/1.1 compliant server
- **Well-maintained**: Official Dart team support

### Connection Management
- **PostgreSQL**: Direct connection (no pooling by default)
- **Redis**: Command-based API

### JSON Serialization
- **Code generation**: json_serializable
- **Type safety**: Compile-time checked
- **Efficient**: Generated code is optimized

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `REDIS_URL` | Redis connection string | Required |
| `DEBUG` | Enable debug mode | false |
| `LOG_LEVEL` | Logging level | info |
| `PORT` | Server port | 3000 |
| `HOST` | Server host | 0.0.0.0 |
| `DB_POOL_MIN` | Min database connections | 5 |
| `DB_POOL_MAX` | Max database connections | 25 |
| `DB_TIMEOUT` | Database timeout (seconds) | 30 |
| `CACHE_TTL` | Cache TTL (seconds) | 300 |

## Benchmarking

### Run Benchmarks

```bash
# Using wrk (installed separately)
./scripts/benchmark-wrk-dart.sh

# Manual wrk commands
wrk -t8 -c200 -d30s --latency http://localhost:3000/health
wrk -t8 -c200 -d30s --latency http://localhost:3000/json
wrk -t8 -c200 -d30s --latency "http://localhost:3000/db/simple?id=1"
wrk -t8 -c200 -d30s --latency "http://localhost:3000/db/complex?days=30"
wrk -t8 -c200 -d30s --latency "http://localhost:3000/cache?key=test"
```

### Expected Performance (Single Instance)

| Endpoint | Throughput (req/s) | Latency p99 |
|----------|-------------------|-------------|
| `/health` | 250,000 - 350,000 | < 5ms |
| `/json` | 180,000 - 280,000 | < 10ms |
| `/db/simple` | 150,000 - 250,000 | < 15ms |
| `/db/complex` | 100,000 - 180,000 | < 30ms |
| `/cache` | 200,000 - 300,000 | < 10ms |

*Dart offers competitive performance with excellent type safety and modern language features*

## Troubleshooting

### Common Issues

**1. "Dart SDK not found"**
```bash
# Check installation
dart --version

# Reinstall
# https://dart.dev/get-dart
```

**2. "Missing generated files"**
```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs
```

**3. "Connection refused"**
```bash
# Check server status
netstat -tuln | grep 3000

# Verify environment
docker exec dart-shelf-app env | grep -E "DATABASE_URL|REDIS_URL"
```

**4. "Compilation errors"**
```bash
# Analyze code
dart analyze

# Fix formatting
dart fix --apply
```

### Health Check Endpoints

```bash
# Application health
curl http://localhost:3000/health

# Kubernetes health check
curl http://localhost:3000/healthz
```

## References

- [Dart Documentation](https://dart.dev/guides)
- [Shelf Framework](https://pub.dev/packages/shelf)
- [shelf_router](https://pub.dev/packages/shelf_router)
- [Dart PostgreSQL](https://pub.dev/packages/postgres)
- [Dart Redis](https://pub.dev/packages/redis)

## License

This benchmark implementation is part of a multi-language REST API comparison project.

## Related Implementations

- [C# .NET 9 Minimal API](../csharp/MinimalApi/)
- [Rust Actix Web](../rust/actix-web/)
- [Java Quarkus](../java/quarkus/)
- [Go Fiber](../go/fiber/)
- [Kotlin Ktor](../kotlin/ktor/)
- [Node.js Fastify](../nodejs/fastify/)
- [Python FastAPI](../python/fastapi/)
- [Bun Elysia](../bun/elysia/)
- [Deno Oak](../deno/oak/)
- **Dart Shelf** (current)
- [GraalVM Vert.x](../graalvm/vertx/)

---

**Status**: Production Ready
**Performance Tier**: High (AOT compilation + Isolates)
**Deployment**: Docker + Kubernetes Ready
**Type Safety**: Sound null safety
**Concurrency**: Isolates for parallelism
