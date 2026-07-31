# 🚀 Node.js Fastify - Quick Reference

## ⚡ Build & Deploy (1 comando)

```bash
cd src/nodejs/fastify
./build.sh docker
```

## 🏃‍♂️ Run Locally

### Development (Hot Reload)
```bash
cd src/nodejs/fastify
./build.sh local
./run.sh dev
```

### Production Mode
```bash
./run.sh start
```

## 📋 Build Options

```bash
./build.sh {local|docker|clean|test|lint|format|docker-push|docker-clean}
```

- **local**: Install dependencies for local development
- **docker**: Build Docker image
- **clean**: Clean node_modules and package-lock.json
- **test**: Run tests
- **lint**: Run linter (eslint)
- **format**: Format code (prettier)
- **docker-push**: Push to registry
- **docker-clean**: Clean Docker images

## 🐳 Docker

### Build
```bash
docker build -t benchmark/nodejs-fastify:latest src/nodejs/fastify
```

### Run
```bash
docker run -p 8080:8080 \
  -e DATABASE_URL="postgresql://..." \
  -e REDIS_URL="redis://..." \
  benchmark/nodejs-fastify:latest
```

### Docker Compose
```bash
cd src/nodejs/fastify
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

# API Documentation
open http://localhost:8080/docs
```

## ⚖️ Kubernetes Deploy

```bash
# Deploy to Kubernetes
kubectl apply -f src/nodejs/fastify/k8s/configmap.yaml -n benchmark
kubectl apply -f src/nodejs/fastify/k8s/deployment.yaml -n benchmark
kubectl apply -f src/nodejs/fastify/k8s/service.yaml -n benchmark

# Wait for pods
kubectl wait --for=condition=ready pod -l app=nodejs-fastify --timeout=120s -n benchmark

# Port-forward
kubectl port-forward -n benchmark svc/nodejs-fastify 8080:80
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
./scripts/benchmark-wrk-nodejs.sh benchmark

# View results
cat /tmp/benchmark-nodejs-report.md
```

## 📊 Performance Features

- **Fastify Framework**: 2x faster than Express
- **Schema Validation**: Zod for type safety
- **Connection Pooling**: PostgreSQL (25 connections)
- **Redis Client**: Connection retry logic
- **Documentation**: Swagger/OpenAPI built-in

## 🔧 Configuration

### Environment Variables
```bash
PORT=8080
NODE_ENV=production
LOG_LEVEL=info
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://user:pass@host:6379
```

### Fastify Settings
```javascript
{
  logger: { level: 'info' },
  trustProxy: true,
  bodyLimit: 1MB,
  requestTimeout: 30s
}
```

## 📁 Project Structure

```
src/nodejs/fastify/
├── package.json              # NPM dependencies
├── Dockerfile                # Multi-stage build
├── docker-compose.yml        # Local orchestration
├── build.sh                  # Build automation
├── run.sh                    # Run automation
├── .env.example              # Environment template
├── .gitignore                # Git ignore rules
├── health-check.js           # K8s health check
├── src/
│   ├── server.js             # Application entry point
│   ├── models/               # Data models with Zod validation
│   ├── services/             # Database + Cache services
│   └── routes/               # HTTP routes with schemas
└── k8s/
    ├── deployment.yaml       # K8s deployment
    ├── service.yaml          # K8s service
    └── configmap.yaml        # K8s config
```

## 🎯 Endpoints Summary

| Endpoint | Method | Validation | DB Query |
|----------|--------|------------|----------|
| `/health` | GET | OpenAPI | SELECT 1 (PostgreSQL + Redis) |
| `/json` | GET | Zod | None (1000 JSON objects) |
| `/db/simple?id={id}` | GET | Zod | Simple SELECT |
| `/db/complex?days={n}` | GET | Zod | JOIN + Aggregation |
| `/cache?key={k}` | GET | Zod | Redis GET/SET (TTL 300s) |

## 🛠️ Development

### Prerequisites
```bash
# Node.js 22+
node --version

# NPM 10+
npm --version
```

### NPM Commands
```bash
# Install dependencies
npm install

# Start production
npm start

# Start development (hot reload)
npm run dev

# Run tests
npm test

# Lint code
npm run lint

# Format code
npm run format
```

## 📈 Expected Performance

Based on Fastify benchmarks:
- **Startup**: 100-500ms
- **Memory**: 50-100 MB
- **Throughput**: 300k-500k req/sec
- **Latency**: 1-3ms p99

### Fastify Advantages
1. **High Performance**: 2x faster than Express.js
2. **Schema Validation**: Zod for type safety
3. **Rich Ecosystem**: Many plugins available
4. **Great DX**: Excellent logging and error handling
5. **TypeScript Support**: First-class TypeScript support
6. **Documentation**: Built-in Swagger/OpenAPI

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

- [Fastify Framework](https://fastify.dev/)
- [Fastify Schemas](https://fastify.dev/docs/latest/Reference/Schemas/)
- [Zod Validation](https://zod.dev/)
- [Node.js pg](https://node-postgres.com/)
- [Redis Node.js](https://redis.js.org/)

## 🔄 Node.js Commands

```bash
# Start server
node src/server.js

# Development mode
node --watch src/server.js

# Run tests
node --test src/**/*.test.js

# Lint code
npx eslint src/**/*.js

# Format code
npx prettier --write src/**/*.js
```

## 📊 Comparison

| Feature | C# (.NET) | Rust | Java (Quarkus) | Go (Fiber) | Kotlin (Ktor) | Node.js (Fastify) |
|---------|-----------|------|----------------|------------|---------------|-------------------|
| Build Time | ~60-70s | ~120-180s | ~180-300s | ~5-10s | ~30-60s | ~10-20s |
| Memory Usage | ~50-80 MB | ~10-20 MB | ~20-40 MB | ~10-20 MB | ~100-200 MB | ~50-100 MB |
| Startup Time | ~50-100ms | ~10-50ms | <50ms | <10ms | 2-3s | 100-500ms |
| Throughput | 400k+/s | 500k+/s | 400k-500k/s | 500k+/s | 300k-400k/s | 300k-500k/s |
| Latency | ~1-2ms | ~0.5-1ms | ~1-2ms | <1ms | 2-3ms | 1-3ms |
| Learning Curve | Medium | High | Medium | Low | Medium | Low |
| Dev Speed | Good | Medium | Good | Excellent | Good | Excellent |
| Ecosystem | Mature | Growing | Very Mature | Mature | Mature | Very Mature |

## 🎉 Key Advantages

1. **Fast Performance**: Fastify is 2x faster than Express
2. **Type Safety**: Zod schema validation
3. **Developer Experience**: Great logging, debugging, error handling
4. **JavaScript Ecosystem**: Largest package ecosystem (npm)
5. **Easy to Learn**: Low learning curve
6. **Async/Await**: Native async support
7. **Hot Reload**: Fast development cycle
8. **Built-in Docs**: Swagger/OpenAPI auto-generated

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/nodejs-fastify:latest`
**Performance**: ⭐⭐⭐⭐ Very Good
**Node.js Version**: 22
**Fastify Version**: 4.28
