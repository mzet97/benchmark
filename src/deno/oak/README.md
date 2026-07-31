# Deno Oak Benchmark Implementation

High-performance REST API implementation using **Deno 2.x runtime** with **Oak framework** - a secure-by-default runtime with built-in TypeScript support and modern web standards.

## 📋 Overview

This implementation provides a complete benchmark-ready REST API leveraging Deno's secure-by-design runtime and Oak's middleware framework, offering excellent performance with TypeScript support out of the box.

### Key Technologies

- **Runtime**: Deno 2.x (secure JavaScript/TypeScript runtime)
- **Framework**: Oak (Koa-inspired middleware framework)
- **Database**: PostgreSQL with deno-postgres driver
- **Cache**: Redis with deno-redis client
- **Type Safety**: Native TypeScript support (no transpilation)
- **Security**: Sandboxed by default, no npm dependencies
- **URL Imports**: Dependencies loaded from CDN URLs

## 🏗️ Architecture

### Project Structure

```
src/deno/oak/
├── server.ts                 # Main application entry point
├── deps.ts                   # External dependencies (CDN imports)
├── types.ts                  # TypeScript type definitions
├── deno.json                 # Deno configuration
├── services/                 # Business logic layer
│   ├── database.ts           # PostgreSQL service
│   └── cache.ts              # Redis service
├── routes/                   # Route handlers
│   ├── health.ts
│   ├── json.ts
│   ├── database.ts
│   └── cache.ts
├── Dockerfile                # Multi-stage Docker build
├── build.sh                  # Build automation script
├── run.sh                    # Run automation script
└── k8s/
    ├── deployment.yaml       # Kubernetes deployment
    ├── service.yaml          # Kubernetes service
    └── configmap.yaml        # Configuration
```

### Design Patterns

- **Middleware Stack**: Oak's middleware composition
- **Type Safety**: Native TypeScript with zero transpilation
- **URL Imports**: Dependencies from CDN (no node_modules)
- **Sandboxing**: Secure by default, permissions-based
- **Connection Pooling**: PostgreSQL and Redis connections
- **Graceful Shutdown**: Cleanup on SIGTERM/SIGINT
- **Error Handling**: Centralized error middleware

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

- Deno 2.x runtime
- PostgreSQL database
- Redis server
- Docker (optional)
- Kubernetes (optional)

### Local Setup

1. **Install Deno**
```bash
# Using installer
curl -fsSL https://deno.land/x/install/install.sh | sh

# Using package manager (macOS)
brew install deno

# Using Scoop (Windows)
scoop install deno
```

2. **Verify Installation**
```bash
deno --version
```

3. **Cache Dependencies**
```bash
cd src/deno/oak
deno cache deps.ts
```

4. **Configure Environment**
```bash
export DATABASE_URL="postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api"
export REDIS_URL="redis://:${REDIS_PASSWORD}@redis.home.arpa:30379"
export DEBUG="false"
```

5. **Run Development Server**
```bash
deno run --allow-net --allow-env --allow-read server.ts
```

6. **Run with Hot Reload**
```bash
deno run --watch --allow-net --allow-env --allow-read server.ts
```

### Permissions

Deno requires explicit permissions:
- `--allow-net`: Network access (database, cache)
- `--allow-env`: Environment variables
- `--allow-read`: File system access

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
docker build -t benchmark/deno-oak:latest .

# Run
docker run -d \
  --name deno-oak-app \
  -p 3000:3000 \
  -e DATABASE_URL="postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:${REDIS_PASSWORD}@redis.home.arpa:30379" \
  benchmark/deno-oak:latest

# Logs
docker logs -f deno-oak-app

# Stop
docker stop deno-oak-app
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
kubectl get pods -l app=deno-oak

# Get service info
kubectl get svc deno-oak

# View logs
kubectl logs -l app=deno-oak -f
```

### Access the API

```bash
# Port forward (development)
kubectl port-forward svc/deno-oak 3000:80

# Service endpoint (cluster)
deno-oak.default.svc.cluster.local
```

## 📊 Performance Features

### Deno Runtime Advantages
- **Secure by default**: Sandboxed execution
- **Native TypeScript**: No transpilation overhead
- **V8 engine**: Same JavaScript engine as Node.js
- **Modern APIs**: Built-in fetch, Web Crypto, etc.
- **URL imports**: No package manager needed
- **Fast startup**: Minimal runtime overhead

### Oak Framework
- **Koa-inspired**: Familiar middleware pattern
- **Type-safe**: Full TypeScript support
- **Composable**: Easy to add middleware
- **Lightweight**: Minimal overhead

### Connection Pooling
- **PostgreSQL**: 5-25 connections (deno-postgres)
- **Redis**: Connection reuse with ping

### Security Features
- **Permission-based**: Explicit access control
- **No node_modules**: Dependencies from CDN
- **Sandboxed**: Isolated execution environment
- **Secure defaults**: No dangerous APIs by default

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
| `DB_TIMEOUT` | Database timeout (ms) | 30000 |
| `CACHE_TTL` | Cache TTL (seconds) | 300 |

## 📈 Benchmarking

### Run Benchmarks

```bash
# Using wrk (installed separately)
./scripts/benchmark-wrk-deno.sh

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
| `/json` | 15,000 - 25,000 | < 8ms |
| `/db/simple` | 12,000 - 20,000 | < 15ms |
| `/db/complex` | 8,000 - 15,000 | < 30ms |
| `/cache` | 18,000 - 28,000 | < 10ms |

*Deno offers competitive performance with Node.js, with the advantage of built-in TypeScript support*

## 🔍 Troubleshooting

### Common Issues

**1. "Permission denied"**
```bash
# Grant permissions explicitly
deno run --allow-net --allow-env --allow-read server.ts
```

**2. "Deno is not installed"**
```bash
# Check installation
deno --version

# Reinstall
curl -fsSL https://deno.land/x/install/install.sh | sh
```

**3. "Connection refused"**
```bash
# Check server status
netstat -tuln | grep 3000

# Verify environment
docker exec deno-oak-app env | grep -E "DATABASE_URL|REDIS_URL"
```

**4. "Module not found"**
```bash
# Check CDN availability
curl -I https://deno.land/x/oak@v17.1.4/mod.ts

# Clear cache
deno cache --reload deps.ts
```

### Health Check Endpoints

```bash
# Application health
curl http://localhost:3000/health

# Kubernetes health check
curl http://localhost:3000/health/healthz
```

## 📚 References

- [Deno Documentation](https://deno.land/manual)
- [Oak Documentation](https://oakserver.github.io/oak/)
- [Deno PostgreSQL](https://deno.land/x/postgres)
- [Deno Redis](https://deno.land/x/redis)

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
- **Deno Oak** (current)

---

**Status**: ✅ Production Ready
**Performance Tier**: High (V8 engine + native TypeScript)
**Deployment**: Docker + Kubernetes Ready
**Security**: Sandboxed by default
**Type Safety**: Native TypeScript support
