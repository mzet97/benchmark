# Node.js Fastify - Benchmark API

High-performance REST API implementation using Node.js 22 and Fastify framework.

## 🚀 Features

- **Framework**: Fastify 4.x (high-performance)
- **Node.js Version**: 22 (latest LTS)
- **Database**: PostgreSQL with node-postgres (pg)
- **Cache**: Redis with node-redis
- **Validation**: Zod schema validation
- **Documentation**: Swagger/OpenAPI built-in
- **Performance**: Low overhead, high throughput

## 📋 Endpoints

1. **GET /health** - Health check
   - Returns: Database and Redis connectivity status
   - Schema: OpenAPI validated

2. **GET /json** - JSON response
   - Returns: 1000 JSON objects
   - Schema: Type-safe with Zod

3. **GET /db/simple?id={id}** - Simple database query
   - Returns: User by ID
   - Query params validated

4. **GET /db/complex?days={days}** - Complex database query
   - Returns: Aggregated order statistics
   - Date range filtering

5. **GET /cache?key={key}** - Cache operations
   - Returns: Cached value or generates new one
   - TTL: 300 seconds

## 🏗️ Build & Run

### Prerequisites

```bash
# Node.js 22+
node --version

# NPM 10+
npm --version

# Docker (optional)
docker --version
```

### Local Development

```bash
# Install dependencies
./build.sh local
# or
npm install

# Run in development mode
./run.sh dev
# or
npm run dev

# Run in production mode
./run.sh start
# or
npm start
```

### Docker Build

```bash
# Build image
./build.sh docker

# Run container
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://..." \
  -e REDIS_URL="redis://..." \
  benchmark/nodejs-fastify:latest
```

### Environment Variables

```bash
PORT=8080
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://user:pass@host:6379
LOG_LEVEL=info
```

## 🧪 Testing

```bash
# Run tests
./run.sh test
# or
npm test

# Lint code
./build.sh lint
# or
npm run lint

# Format code
./build.sh format
# or
npm run format
```

## 📊 Performance

### Expected Characteristics
- **Startup Time**: 100-500ms
- **Memory Footprint**: 50-100 MB
- **Throughput**: 300k-500k req/sec
- **Latency**: 1-3ms p99
- **Schema Validation**: Zod (compile-time safe)

### Fastify Advantages
- **High Performance**: 2x faster than Express
- **Schema Validation**: Type-safe request/response
- **Plugins**: Rich ecosystem
- **Developer Experience**: Great logging and debugging

## 🔧 Configuration

### Database Connection
```javascript
const pool = new Pool({
  connectionString: dbUrl,
  max: 25,
  min: 5,
  idleTimeoutMillis: 30000,
});
```

### Redis Connection
```javascript
const client = createClient({
  url: redisUrl,
  socket: {
    reconnectStrategy: (retries) => Math.min(retries * 50, 500)
  }
});
```

### Fastify Options
```javascript
const fastify = Fastify({
  logger: { level: 'info' },
  trustProxy: true,
  bodyLimit: 1 * 1024 * 1024, // 1MB
  requestTimeout: 30000,
});
```

## 📦 Dependencies

### Core
- `fastify` - Web framework
- `@fastify/cors` - CORS support
- `@fastify/sensible` - Sensible defaults
- `@fastify/swagger` - Swagger documentation

### Database
- `pg` - PostgreSQL driver
- `redis` - Redis client

### Validation
- `zod` - Schema validation
- `fastify-type-provider-zod` - Fastify Zod provider

### Utilities
- `uuid` - UUID generation

## 🐳 Kubernetes

Deploy with:
```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Port-forward:
```bash
kubectl port-forward svc/nodejs-fastify 8080:80
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
src/nodejs/fastify/
├── package.json                             # NPM dependencies
├── Dockerfile                               # Multi-stage build
├── docker-compose.yml                       # Local orchestration
├── build.sh                                 # Build automation
├── run.sh                                   # Run automation
├── .env.example                             # Environment template
├── .gitignore                               # Git ignore rules
├── README.md                                # This file
├── health-check.js                          # K8s health check
├── src/
│   ├── server.js                           # Application entry point
│   ├── models/                             # Data models
│   │   ├── User.js                         # User model with Zod
│   │   ├── Order.js                        # Order model
│   │   ├── ComplexOrderResult.js           # Aggregation result
│   │   ├── JsonItem.js                     # JSON response item
│   │   └── HealthResponse.js               # Health response
│   ├── services/                           # Business logic
│   │   ├── DatabaseService.js              # PostgreSQL with pg
│   │   └── CacheService.js                 # Redis client
│   └── routes/                             # HTTP routes
│       ├── health.js                       # /health endpoint
│       ├── json.js                         # /json endpoint
│       ├── database.js                     # /db/simple & /db/complex
│       └── cache.js                        # /cache endpoint
└── k8s/
    ├── deployment.yaml                     # K8s deployment
    ├── service.yaml                        # K8s service
    └── configmap.yaml                      # K8s config
```

## 🎯 Endpoints Summary

| Endpoint | Method | Schema | DB Query |
|----------|--------|--------|----------|
| `/health` | GET | OpenAPI | SELECT 1 |
| `/json` | GET | Zod | None |
| `/db/simple?id={id}` | GET | Zod | Simple SELECT |
| `/db/complex?days={n}` | GET | Zod | JOIN + Aggregation |
| `/cache?key={k}` | GET | Zod | Redis |

## 🛠️ Development

### Build Options
```bash
./build.sh {local|docker|clean|test|lint|format|docker-push}
```

### Run Modes
```bash
./run.sh {dev|start|docker|test}
```

### NPM Commands
```bash
npm start           # Start production server
npm run dev         # Start with hot reload
npm test            # Run tests
npm run lint        # Lint code
npm run format      # Format code
```

## 📈 Expected Performance

Based on Fastify benchmarks:
- **Throughput**: 300k-500k req/sec
- **Latency**: 1-3ms p99
- **Memory**: 50-100 MB
- **Startup**: 100-500ms

## ❌ Troubleshooting

### Build Errors
```bash
# Clean and rebuild
./build.sh clean
./build.sh local

# Check Node.js version
node --version
```

### Connection Errors
```bash
# Test PostgreSQL
psql "postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api"

# Test Redis
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

- [Fastify Guide](https://fastify.dev/)
- [Fastify Schema](https://fastify.dev/docs/latest/Reference/Schemas/)
- [Zod Validation](https://zod.dev/)
- [Node.js PostgreSQL](https://node-postgres.com/)
- [Redis Node.js](https://redis.js.org/)

## 📝 License

MIT

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/nodejs-fastify:latest`
**Performance**: ⭐⭐⭐⭐ Very Good
