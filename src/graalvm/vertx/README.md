# GraalVM Vert.x Benchmark Implementation

High-performance REST API implementation using **GraalVM 21** with **Vert.x** - a reactive, event-driven application framework with Polyglot support and Native Image compilation capabilities.

## 📋 Overview

This implementation provides a complete benchmark-ready REST API leveraging GraalVM's high-performance runtime and Vert.x's reactive programming model for building distributed systems.

### Key Technologies

- **Runtime**: GraalVM 21 (JIT + AOT compilation)
- **Framework**: Vert.x 4.x (reactive event-driven)
- **Database**: PostgreSQL with vertx-pg-client
- **Cache**: Redis with vertx-redis-client
- **Language**: Java 21 (virtual threads, pattern matching)
- **Build**: Maven with Native Image support
- **JSON**: Vert.x JSON + Jackson

## 🏗️ Architecture

### Project Structure

```
src/graalvm/vertx/
├── src/main/java/com/benchmark/vertx/
│   ├── Main.java                      # Application entry point
│   ├── config/
│   │   └── Config.java                # Configuration management
│   ├── server/
│   │   └── VertxServer.java           # HTTP server setup
│   ├── handlers/                      # Route handlers
│   │   ├── HealthHandler.java
│   │   ├── JsonHandler.java
│   │   ├── DatabaseHandler.java
│   │   └── CacheHandler.java
│   ├── services/                      # Business logic layer
│   │   ├── DatabaseService.java       # PostgreSQL service
│   │   └── CacheService.java          # Redis service
│   └── middleware/                    # HTTP middleware
│       ├── LoggingHandler.java
│       ├── ErrorHandler.java
│       └── CorsHandler.java
├── pom.xml                            # Maven configuration
├── Dockerfile                         # Multi-stage Docker build
├── build.sh                           # Build automation script
├── run.sh                             # Run automation script
└── k8s/
    ├── deployment.yaml                # Kubernetes deployment
    ├── service.yaml                   # Kubernetes service
    └── configmap.yaml                 # Configuration
```

### Design Patterns

- **Reactive Programming**: Non-blocking I/O with Vert.x
- **Event-Driven**: Asynchronous event processing
- **Verticle Pattern**: Modular, scalable components
- **Handler Chain**: Composable middleware
- **Future/Promise**: Asynchronous operations
- **Connection Pooling**: PostgreSQL and Redis pools

## 🚀 Endpoints

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

## 🛠️ Development

### Prerequisites

- GraalVM 21+ JDK
- Maven 3.9+
- PostgreSQL database
- Redis server
- Docker (optional)
- Kubernetes (optional)

### Local Setup

1. **Install GraalVM**
```bash
# Download from https://www.graalvm.org/downloads/
# Set JAVA_HOME to GraalVM installation
export JAVA_HOME=/path/to/graalvm
```

2. **Verify Installation**
```bash
java -version
```

3. **Build Project**
```bash
cd src/graalvm/vertx
mvn clean package
```

4. **Configure Environment**
```bash
export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
export DEBUG="false"
```

5. **Run Application**
```bash
mvn vertx:run
```

6. **Build Native Image (Optional)**
```bash
mvn -Pnative -DskipTests clean package
./target/graalvm-vertx-benchmark
```

## 🐳 Docker

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
docker build -t benchmark/graalvm-vertx:latest .

# Run
docker run -d \
  --name graalvm-vertx-app \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
  benchmark/graalvm-vertx:latest

# Logs
docker logs -f graalvm-vertx-app

# Stop
docker stop graalvm-vertx-app
```

## ☸️ Kubernetes

### Deploy to K8s

```bash
# Apply manifests
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Verify deployment
kubectl get deployments
kubectl get pods -l app=graalvm-vertx

# Get service info
kubectl get svc graalvm-vertx

# View logs
kubectl logs -l app=graalvm-vertx -f
```

### Access the API

```bash
# Port forward (development)
kubectl port-forward svc/graalvm-vertx 3000:80

# Service endpoint (cluster)
graalvm-vertx.default.svc.cluster.local
```

## 📊 Performance Features

### GraalVM Advantages
- **JIT + AOT**: Best of both worlds (dev speed + prod performance)
- **Native Image**: Sub-100ms startup time
- **Polyglot**: Support for multiple languages
- **Advanced GC**: G1GC, ZGC, Shenandoah
- **Optimizations**: Tiered compilation, inlining

### Vert.x Framework
- **Reactive**: Non-blocking I/O
- **Event Loop**: High throughput
- **Verticles**: Scalable deployment units
- **Handler-based**: Clean async API
- **Circuit Breaker**: Resilience patterns

### Connection Pooling
- **PostgreSQL**: 5-25 connections (vertx-pg-client)
- **Redis**: Connection reuse

### Async Operations
- **Futures/Promises**: Non-blocking composition
- **Event Bus**: Inter-verticle communication
- **Shared Data**: Distributed state

## 🔧 Configuration

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
| `CACHE_TTL` | Cache TTL (seconds) | 300 |

## 📈 Benchmarking

### Run Benchmarks

```bash
# Using wrk (installed separately)
./scripts/benchmark-wrk-graalvm.sh

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
| `/health` | 20,000 - 30,000 | < 5ms |
| `/json` | 15,000 - 25,000 | < 10ms |
| `/db/simple` | 12,000 - 20,000 | < 15ms |
| `/db/complex` | 8,000 - 15,000 | < 30ms |
| `/cache` | 18,000 - 28,000 | < 10ms |

*Performance with Native Image can be even better with instant startup*

## 🔍 Troubleshooting

### Common Issues

**1. "GraalVM not found"**
```bash
# Check installation
java -version

# Set JAVA_HOME
export JAVA_HOME=/path/to/graalvm
```

**2. "Native Image build fails"**
```bash
# Check GraalVM installation
native-image --version

# Build with verbose output
mvn -Pnative -DskipTests clean package -X
```

**3. "Connection refused"**
```bash
# Check server status
netstat -tuln | grep 3000

# Verify environment
docker exec graalvm-vertx-app env | grep -E "DATABASE_URL|REDIS_URL"
```

**4. "Compilation errors"**
```bash
# Clean and rebuild
mvn clean compile

# Check dependencies
mvn dependency:tree
```

### Health Check Endpoints

```bash
# Application health
curl http://localhost:3000/health

# Kubernetes health check
curl http://localhost:3000/healthz
```

## 📚 References

- [GraalVM Documentation](https://www.graalvm.org/)
- [Vert.x Documentation](https://vertx.io/docs/)
- [Vert.x PostgreSQL](https://vertx.io/docs/vertx-pg-client/java/)
- [Vert.x Redis](https://vertx.io/docs/vertx-redis-client/java/)

## 📝 License

This benchmark implementation is part of a multi-language REST API comparison project.

## 🔄 Related Implementations

- [C# .NET 9 Minimal API](../csharp/MinimalApi/)
- [Rust Actix Web](../rust/actix-web/)
- [Java Quarkus](../java/quarkus/)
- [Go Fiber](../go/fiber/)
- [Kotlin Ktor](../kotlin/ktor/)
- [Node.js Fastify](../nodejs/fastify/)
- [Python FastAPI](../python/fastapi/)
- [Bun Elysia](../bun/elysia/)
- [Deno Oak](../deno/oak/)
- [Dart Vaden](../dart/vaden/)
- **GraalVM Vert.x** (current)

---

**Status**: ✅ Production Ready
**Performance Tier**: High (JIT + Native Image)
**Deployment**: Docker + Kubernetes Ready
**Reactive**: Event-driven, non-blocking I/O
**Polyglot**: Multi-language support
