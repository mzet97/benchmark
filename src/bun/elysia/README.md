# Bun Elysia Benchmark Implementation

High-performance REST API implementation using **Bun runtime** with **Elysia framework** - built from the ground up for speed with native TypeScript/ESM support.

## 📋 Overview

This implementation provides a complete benchmark-ready REST API leveraging Bun's ultra-fast JavaScript runtime and Elysia's ergonomic web framework, offering performance comparable to compiled languages.

### Key Technologies

- **Runtime**: Bun 1.x (JavaScript/TypeScript runtime)
- **Framework**: Elysia (fast HTTP web framework)
- **Database**: PostgreSQL with node-postgres (pg)
- **Cache**: Redis with ioredis-compatible client
- **Validation**: TypeBox (TypeScript type system)
- **Logging**: Pino (high-performance JSON logger)
- **Documentation**: Built-in Swagger/OpenAPI

## 🏗️ Architecture

### Project Structure

```
src/bun/elysia/
├── src/
│   ├── server.ts                 # Main application entry point
│   ├── types.ts                  # TypeScript type definitions
│   ├── services/                 # Business logic layer
│   │   ├── database.ts           # PostgreSQL service
│   │   └── cache.ts              # Redis service
│   └── routes/                   # Route handlers
│       ├── health.ts
│       ├── json.ts
│       ├── database.ts
│       └── cache.ts
├── Dockerfile                    # Multi-stage Docker build
├── build.sh                      # Build automation script
├── run.sh                        # Run automation script
├── package.json                  # Bun dependencies
├── tsconfig.json                 # TypeScript configuration
└── k8s/
    ├── deployment.yaml           # Kubernetes deployment
    ├── service.yaml              # Kubernetes service
    └── configmap.yaml            # Configuration
```

### Design Patterns

- **Plugin Architecture**: Elysia's modular plugin system
- **Type Safety**: Full TypeScript type coverage with TypeBox
- **Connection Pooling**: PostgreSQL and Redis connection pools
- **Middleware Stack**: CORS, Swagger, request logging
- **Graceful Shutdown**: Cleanup on SIGTERM/SIGINT
- **Error Handling**: Centralized error handler with logging

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
  "timestamp": "2025-12-07T10:30:00Z",
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

- Bun 1.0+ runtime
- PostgreSQL database
- Redis server
- Docker (optional)
- Kubernetes (optional)

### Local Setup

1. **Install Bun**
```bash
curl -fsSL https://bun.sh/install | bash
# or
npm install -g bun
```

2. **Install Dependencies**
```bash
cd src/bun/elysia
bun install
```

3. **Configure Environment**
```bash
export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
export DEBUG="false"
```

4. **Run Development Server**
```bash
bun run dev
```

5. **Run Production**
```bash
bun start
```

### API Documentation

Once running, access the interactive API documentation:
- **Swagger UI**: http://localhost:3000/docs
- **OpenAPI JSON**: http://localhost:3000/docs/json

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
docker build -t benchmark/bun-elysia:latest .

# Run
docker run -d \
  --name bun-elysia-app \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
  benchmark/bun-elysia:latest

# Logs
docker logs -f bun-elysia-app

# Stop
docker stop bun-elysia-app
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
kubectl get pods -l app=bun-elysia

# Get service info
kubectl get svc bun-elysia

# View logs
kubectl logs -l app=bun-elysia -f
```

### Access the API

```bash
# Port forward (development)
kubectl port-forward svc/bun-elysia 3000:80

# Service endpoint (cluster)
bun-elysia.default.svc.cluster.local
```

## 📊 Performance Features

### Bun Runtime Advantages
- **3-4x faster** than Node.js for HTTP requests
- **Native ESM support** without transpilation overhead
- **Built-in bundler** and minifier
- **Optimized garbage collection**
- **Web-standard APIs** (fetch, WebSocket, etc.)

### Elysia Framework
- **Decorator-based** routing
- **Plugin system** for modularity
- **TypeBox integration** for runtime validation
- **Minimal overhead** (comparable to Express/Fastify)

### Connection Pooling
- **PostgreSQL**: 5-25 connections (node-postgres)
- **Redis**: Connection reuse with automatic reconnection

### Logging
- **Pino**: High-performance JSON logging
- **Request tracking**: Method, URL, status, process time
- **Error context**: Full error details in development

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
| `DB_TIMEOUT` | Database timeout (ms) | 10000 |
| `DB_IDLE_TIMEOUT` | Idle timeout (ms) | 30000 |
| `CACHE_TTL` | Cache TTL (seconds) | 300 |

## 📈 Benchmarking

### Run Benchmarks

```bash
# Using wrk (installed separately)
./scripts/benchmark-wrk-bun.sh

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
| `/health` | 35,000 - 50,000 | < 3ms |
| `/json` | 25,000 - 35,000 | < 5ms |
| `/db/simple` | 20,000 - 30,000 | < 8ms |
| `/db/complex` | 12,000 - 18,000 | < 20ms |
| `/cache` | 30,000 - 45,000 | < 5ms |

*Bun runtime delivers exceptional performance, often 3-4x faster than Node.js*

## 🔍 Troubleshooting

### Common Issues

**1. "Bun is not installed"**
```bash
# Install Bun
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
bun --version
```

**2. Connection Refused**
```bash
# Check server status
netstat -tuln | grep 3000

# Verify environment
docker exec bun-elysia-app env | grep -E "DATABASE_URL|REDIS_URL"
```

**3. Database Connection Errors**
```bash
# Test database connectivity
psql "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" -c "SELECT 1;"
```

**4. Redis Connection Errors**
```bash
# Test Redis connectivity
redis-cli -h redis.home.arpa -p 30379 -a Admin@123 ping
```

### Health Check Endpoints

```bash
# Application health
curl http://localhost:3000/health

# Kubernetes health check
curl http://localhost:3000/healthz
```

## 📚 References

- [Bun Documentation](https://bun.sh/docs)
- [Elysia Documentation](https://elysiajs.com/)
- [TypeBox Documentation](https://sinclair.typebox.io/)
- [Pino Logging](https://github.com/pinojs/pino)

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
- **Bun Elysia** (current)

---

**Status**: ✅ Production Ready
**Performance Tier**: Excellent (3-4x faster than Node.js)
**Deployment**: Docker + Kubernetes Ready
**Monitoring**: Health Checks + Structured Logging
**Type Safety**: Full TypeScript coverage
