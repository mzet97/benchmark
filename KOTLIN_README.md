# 🚀 Kotlin Ktor - Quick Reference

## ⚡ Build & Deploy (1 comando)

```bash
cd src/kotlin/ktor
./build.sh docker
```

## 🏃‍♂️ Run Locally

### Development
```bash
cd src/kotlin/ktor
./build.sh local
./run.sh dev
```

### Build Fat JAR
```bash
./build.sh fatJar
```

## 📋 Build Options

```bash
./build.sh {local|docker|clean|test|fatJar|docker-push|install-deps}
```

- **local**: Build for local development
- **docker**: Build Docker image
- **clean**: Clean build artifacts
- **test**: Run tests
- **fatJar**: Build fat JAR (self-contained)
- **docker-push**: Push to registry
- **install-deps**: Install dependencies

## 🐳 Docker

### Build
```bash
docker build -t benchmark/kotlin-ktor:latest src/kotlin/ktor
```

### Run
```bash
docker run -p 8080:8080 \
  -e DATABASE_URL="jdbc:postgresql://..." \
  -e DATABASE_USER="..." \
  -e DATABASE_PASSWORD="..." \
  -e REDIS_URL="redis://..." \
  benchmark/kotlin-ktor:latest
```

### Docker Compose
```bash
cd src/kotlin/ktor
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
kubectl apply -f src/kotlin/ktor/k8s/configmap.yaml -n benchmark
kubectl apply -f src/kotlin/ktor/k8s/deployment.yaml -n benchmark
kubectl apply -f src/kotlin/ktor/k8s/service.yaml -n benchmark

# Wait for pods
kubectl wait --for=condition=ready pod -l app=kotlin-ktor --timeout=120s -n benchmark

# Port-forward
kubectl port-forward -n benchmark svc/kotlin-ktor 8080:80
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
./scripts/benchmark-wrk-kotlin.sh benchmark

# View results
cat /tmp/benchmark-kotlin-report.md
```

## 📊 Performance Features

- **Ktor Framework**: Modern async web framework
- **Coroutines**: Suspend functions for async/await
- **HikariCP**: High-performance connection pooling
- **Lettuce**: Reactive Redis client
- **Type Safety**: Compile-time checks

## 🔧 Configuration

### Environment Variables
```bash
PORT=8080
DATABASE_URL=jdbc:postgresql://user:pass@host:5432/db
DATABASE_USER=user
DATABASE_PASSWORD=password
REDIS_URL=redis://user:pass@host:6379
```

### Application Properties
```kotlin
// HikariCP settings
maximumPoolSize = 25
minimumIdle = 5
connectionTimeout = 5000
```

## 📁 Project Structure

```
src/kotlin/ktor/
├── build.gradle.kts           # Gradle Kotlin DSL
├── Dockerfile                 # Multi-stage build
├── docker-compose.yml         # Local orchestration
├── build.sh                   # Build automation
├── run.sh                     # Run automation
├── .env.example               # Environment template
├── .gitignore                 # Git ignore rules
├── src/main/kotlin/com/benchmark/
│   ├── Application.kt         # Application entry
│   ├── models/                # Data models (User, Order, etc.)
│   ├── services/              # Database + Cache services
│   ├── routes/                # HTTP routes (endpoints)
│   └── plugins/               # Ktor plugins (config)
└── k8s/
    ├── deployment.yaml        # K8s deployment
    ├── service.yaml           # K8s service
    └── configmap.yaml         # K8s config
```

## 🎯 Endpoints Summary

| Endpoint | Method | Type | DB Query |
|----------|--------|------|----------|
| `/health` | GET | Suspend | SELECT 1 (PostgreSQL + Redis) |
| `/json` | GET | Suspend | None (1000 JSON objects) |
| `/db/simple?id={id}` | GET | Suspend | Simple SELECT |
| `/db/complex?days={n}` | GET | Suspend | JOIN + Aggregation |
| `/cache?key={k}` | GET | Suspend | Redis GET/SET (TTL 300s) |

## 🛠️ Development

### Prerequisites
```bash
# Java 21
java -version

# Gradle 8+
gradle --version
```

### Build & Run Cycle
```bash
# Build
./build.sh local

# Run
./run.sh dev

# Test
./build.sh test

# Clean
./build.sh clean
```

### Gradle Commands
```bash
# Build project
gradle build --no-daemon

# Run tests
gradle test --no-daemon

# Build fat JAR
gradle fatJar --no-daemon

# Clean
gradle clean --no-daemon
```

## 📈 Expected Performance

Based on Kotlin/JVM benchmarks:
- **Startup**: 2-3 seconds
- **Memory**: 100-200 MB
- **Throughput**: 300k-400k req/sec
- **Latency**: 2-3ms p99

### Kotlin Advantages
1. **Concise Syntax**: Less boilerplate than Java
2. **Coroutines**: Lightweight async/await
3. **Type Safety**: Compile-time error checking
4. **Null Safety**: Built-in null safety
5. **JVM Ecosystem**: All Java libraries available

## ❌ Troubleshooting

### Build Errors
```bash
# Clean and rebuild
./build.sh clean
./build.sh local

# Check versions
java -version
gradle --version
```

### Connection Errors
```bash
# Test PostgreSQL
psql "jdbc:postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"

# Test Redis
redis-cli -h redis.home.arpa -p 30379 -a Admin@123 PING
```

### Port Already in Use
```bash
# Find process
lsof -i :8080

# Kill process
kill -9 <PID>
```

## 📚 Documentation

- [Ktor Framework](https://ktor.io/docs/)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Kotlin Serialization](https://kotlinlang.org/docs/serialization.html)
- [HikariCP](https://github.com/brettwooldridge/HikariCP)
- [Lettuce Redis](https://lettuce.io/)

## 🔄 Kotlin Commands

```bash
# Build with Gradle
gradle build --no-daemon

# Run fat JAR
java -jar build/libs/benchmark-ktor.jar

# Run tests
gradle test --no-daemon

# Build fat JAR
gradle fatJar --no-daemon
```

## 📊 Comparison

| Feature | C# (.NET) | Rust | Java (Quarkus) | Go (Fiber) | Kotlin (Ktor) |
|---------|-----------|------|----------------|------------|---------------|
| Build Time | ~60-70s | ~120-180s | ~180-300s | ~5-10s | ~30-60s |
| Binary Size | ~80-100 MB | ~15-20 MB | ~60-80 MB | ~15-25 MB | ~50-80 MB |
| Memory Usage | ~50-80 MB | ~10-20 MB | ~20-40 MB | ~10-20 MB | ~100-200 MB |
| Startup Time | ~50-100ms | ~10-50ms | <50ms | <10ms | 2-3s |
| Throughput | 400k+/s | 500k+/s | 400k-500k/s | 500k+/s | 300k-400k/s |
| Latency | ~1-2ms | ~0.5-1ms | ~1-2ms | <1ms | 2-3ms |
| Learning Curve | Medium | High | Medium | Low | Medium |
| Dev Speed | Good | Medium | Good | Excellent | Good |
| Concurrency | Async/Await | Async/Await | Uni/Mutiny | Goroutines | Coroutines |

## 🎉 Key Advantages

1. **Modern Language**: Kotlin 2.0 with latest features
2. **Coroutines**: Async/await for non-blocking I/O
3. **Type Safety**: Compile-time error checking
4. **Concise**: Less boilerplate than Java
5. **JVM**: Mature ecosystem and tooling
6. **Interoperability**: 100% Java compatible

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/kotlin-ktor:latest`
**Performance**: ⭐⭐⭐⭐ Very Good
**Kotlin Version**: 2.0
**Ktor Version**: 3.0
