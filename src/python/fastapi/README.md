# Python FastAPI Benchmark Implementation

High-performance REST API implementation using **Python 3.12** and **FastAPI** framework with async PostgreSQL (asyncpg) and Redis (aioredis) support.

## 📋 Overview

This implementation provides a complete benchmark-ready REST API with optimized async I/O operations, following Python best practices for high-performance web services.

### Key Technologies

- **Framework**: FastAPI 0.115+ (Python 3.12+)
- **Database**: PostgreSQL with asyncpg driver
- **Cache**: Redis with aioredis client
- **Validation**: Pydantic v2 models
- **Logging**: Structured logging with structlog
- **Server**: Uvicorn ASGI server

## 🏗️ Architecture

### Project Structure

```
src/python/fastapi/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── models/                 # Pydantic models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── order.py
│   │   ├── complex_order.py
│   │   ├── json_item.py
│   │   ├── health.py
│   │   └── cache.py
│   ├── services/               # Business logic layer
│   │   ├── __init__.py
│   │   ├── database.py         # PostgreSQL async service
│   │   └── cache.py            # Redis async service
│   └── routes/                 # API route handlers
│       ├── __init__.py
│       ├── health.py
│       ├── json.py
│       ├── database.py
│       └── cache.py
├── Dockerfile                  # Multi-stage Docker build
├── build.sh                    # Build automation script
├── run.sh                      # Run automation script
├── requirements.txt            # Python dependencies
└── k8s/
    ├── deployment.yaml         # Kubernetes deployment
    ├── service.yaml            # Kubernetes service
    └── configmap.yaml          # Configuration
```

### Design Patterns

- **Layered Architecture**: Clear separation between routes, services, and models
- **Async/Await**: Fully asynchronous I/O operations
- **Dependency Injection**: FastAPI's built-in DI for services
- **Connection Pooling**: Optimized database and Redis connection pools
- **Middleware**: Request logging, CORS, and error handling
- **Health Checks**: Kubernetes-ready liveness and readiness probes

## 🚀 Endpoints

### 1. Health Check
```http
GET /health
```
Returns API health status and version information.

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-12-07T10:30:00Z"
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

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "created_at": "2025-01-15T10:30:00Z"
}
```

### 4. Complex Database Query
```http
GET /db/complex?days={days}
```
Performs JOIN query with aggregation over specified days.

**Parameters:**
- `days` (integer, optional, default: 30): Number of days to look back

**Response:**
```json
{
  "period_days": 30,
  "total_orders": 150,
  "total_revenue": 12500.75,
  "average_order_value": 83.34,
  "orders": [
    {
      "order_id": 123,
      "user_id": 1,
      "user_email": "user@example.com",
      "total_amount": 125.50,
      "items_count": 3,
      "created_at": "2025-12-01T10:30:00Z"
    }
  ]
}
```

### 5. Cache Operations
```http
GET /cache?key={key}
```
Performs Redis cache GET/SET operations with TTL.

**Parameters:**
- `key` (string, required): Cache key

**Response:**
```json
{
  "key": "test",
  "value": "cached_data",
  "cached": false,
  "ttl": 300
}
```

## 🛠️ Development

### Prerequisites

- Python 3.12+
- PostgreSQL (asyncpg driver)
- Redis (aioredis client)
- Docker (optional)
- Kubernetes (optional)

### Local Setup

1. **Install Dependencies**
```bash
cd src/python/fastapi
pip install -r requirements.txt
```

2. **Configure Environment**
```bash
export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
export DEBUG="true"
```

3. **Run Development Server**
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

4. **Run with Auto-reload**
```bash
python -m uvicorn app.main:app --reload
```

### API Documentation

Once running, access the interactive API documentation:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

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
docker build -t benchmark/python-fastapi:latest .

# Run
docker run -d \
  --name python-fastapi-app \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
  benchmark/python-fastapi:latest

# Logs
docker logs -f python-fastapi-app

# Stop
docker stop python-fastapi-app
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
kubectl get pods -l app=python-fastapi

# Get service info
kubectl get svc python-fastapi

# View logs
kubectl logs -l app=python-fastapi -f
```

### Access the API

```bash
# Port forward (development)
kubectl port-forward svc/python-fastapi 8000:80

# Service endpoint (cluster)
python-fastapi.default.svc.cluster.local
```

### Scale Deployment

```bash
# Scale to 10 replicas
kubectl scale deployment python-fastapi --replicas=10

# Auto-scaling (requires metrics-server)
kubectl autoscale deployment python-fastapi \
  --cpu-percent=70 \
  --min=5 \
  --max=20
```

## 📊 Performance Features

### Async I/O Optimization
- **asyncpg**: Native async PostgreSQL driver (no thread pooling overhead)
- **aioredis**: Async Redis client with connection pooling
- **Uvicorn**: High-performance ASGI server

### Connection Pooling
- **Database**: 5-25 connections (configurable)
- **Redis**: Connection reuse with health checks

### Memory Efficiency
- **Pydantic**: Efficient data validation and serialization
- **Structlog**: Structured JSON logging
- **Single Worker**: Reduced memory footprint (can scale via K8s)

### Latency Optimization
- **Keep-alive**: HTTP keep-alive connections
- **Prepared Statements**: Database query optimization
- **TTL Caching**: 300-second Redis TTL

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `REDIS_URL` | Redis connection string | Required |
| `DEBUG` | Enable debug mode | false |
| `LOG_LEVEL` | Logging level (DEBUG, INFO, WARNING, ERROR) | INFO |
| `SERVER_HOST` | Server bind host | 0.0.0.0 |
| `SERVER_PORT` | Server port | 8000 |
| `SERVER_WORKERS` | Number of Uvicorn workers | 1 |
| `DB_POOL_MIN` | Min database connections | 5 |
| `DB_POOL_MAX` | Max database connections | 25 |
| `DB_TIMEOUT` | Database timeout (seconds) | 30 |
| `CACHE_TTL` | Cache TTL (seconds) | 300 |

### Connection String Formats

**PostgreSQL:**
```
postgresql://username:password@host:port/database
```

**Redis:**
```
redis://[:password]@host:port/db
redis://[:password]@host:port
```

## 📈 Benchmarking

### Run Benchmarks

```bash
# Using wrk (installed separately)
./scripts/benchmark-wrk-python.sh

# Manual wrk commands
wrk -t8 -c200 -d30s --latency http://localhost:8000/health
wrk -t8 -c200 -d30s --latency http://localhost:8000/json
wrk -t8 -c200 -d30s --latency "http://localhost:8000/db/simple?id=1"
wrk -t8 -c200 -d30s --latency "http://localhost:8000/db/complex?days=30"
wrk -t8 -c200 -d30s --latency "http://localhost:8000/cache?key=test"
```

### Expected Performance (Single Instance)

| Endpoint | Throughput (req/s) | Latency p99 |
|----------|-------------------|-------------|
| `/health` | 15,000 - 20,000 | < 5ms |
| `/json` | 8,000 - 12,000 | < 15ms |
| `/db/simple` | 6,000 - 10,000 | < 20ms |
| `/db/complex` | 3,000 - 5,000 | < 50ms |
| `/cache` | 10,000 - 15,000 | < 10ms |

*Performance varies based on hardware, database load, and network conditions.*

## 🔍 Troubleshooting

### Common Issues

**1. Connection Refused**
```bash
# Check if services are running
netstat -tuln | grep 8000

# Verify environment variables
docker exec python-fastapi-app env | grep -E "DATABASE_URL|REDIS_URL"
```

**2. Database Connection Errors**
```bash
# Test database connectivity
psql "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" -c "SELECT 1;"

# Check connection pool
curl http://localhost:8000/health | jq '.database'
```

**3. Redis Connection Errors**
```bash
# Test Redis connectivity
redis-cli -h redis.home.arpa -p 30379 -a Admin@123 ping

# Check cache operations
curl http://localhost:8000/cache?key=test | jq '.cached'
```

**4. High Memory Usage**
```bash
# Monitor container resources
docker stats python-fastapi-app

# Check for memory leaks
kubectl top pods -l app=python-fastapi
```

**5. Slow Performance**
```bash
# Enable debug logging
export LOG_LEVEL=DEBUG

# Check database query performance
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8000/db/complex?days=30"
```

### Health Check Endpoints

```bash
# Application health
curl http://localhost:8000/health

# Kubernetes health check
curl http://localhost:8000/healthz

# Database connectivity
curl http://localhost:8000/health | jq '.database'

# Cache connectivity
curl http://localhost:8000/health | jq '.cache'
```

## 📚 References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [asyncpg Documentation](https://asyncpg.readthedocs.io/)
- [aioredis Documentation](https://aioredis.readthedocs.io/)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [Uvicorn Documentation](https://www.uvicorn.org/)
- [Structlog Documentation](https://www.structlog.org/)

## 📝 License

This benchmark implementation is part of a multi-language REST API comparison project.

## 🤝 Contributing

This is a benchmark project. Contributions should focus on performance optimization and correctness.

## 🔄 Related Implementations

- [C# .NET 9 Minimal API](../csharp/MinimalApi/)
- [Rust Actix Web](../rust/actix-web/)
- [Java Quarkus](../java/quarkus/)
- [Go Fiber](../go/fiber/)
- [Kotlin Ktor](../kotlin/ktor/)
- [Node.js Fastify](../nodejs/fastify/)
- **Python FastAPI** (current)

---

**Status**: ✅ Production Ready
**Performance Tier**: High (Async I/O)
**Deployment**: Docker + Kubernetes Ready
**Monitoring**: Health Checks + Structured Logging
