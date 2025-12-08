# Kotlin Ktor - Benchmark API

High-performance REST API implementation using Kotlin 2.0 and Ktor framework.

## 🚀 Features

- **Framework**: Ktor 3.x (JetBrains)
- **Kotlin Version**: 2.0 (latest)
- **Database**: PostgreSQL with HikariCP connection pooling
- **Cache**: Redis with Lettuce client
- **Coroutines**: Suspend functions for async/await
- **Performance**: Low latency, high throughput

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
# Java 21+
java -version

# Gradle 8+
gradle --version

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
  -e DATABASE_URL="jdbc:postgresql://..." \
  -e DATABASE_USER="..." \
  -e DATABASE_PASSWORD="..." \
  -e REDIS_URL="redis://..." \
  benchmark/kotlin-ktor:latest
```

### Environment Variables

```bash
PORT=8080
DATABASE_URL=jdbc:postgresql://user:pass@host:5432/db
DATABASE_USER=user
DATABASE_PASSWORD=password
REDIS_URL=redis://user:pass@host:6379
```

## 🧪 Testing

```bash
# Run tests
./build.sh test

# Run with coverage
gradle test --no-daemon jacocoTestReport
```

## 📊 Performance

### Expected Characteristics
- **Startup Time**: 2-3 seconds
- **Memory Footprint**: 100-200 MB
- **Throughput**: 300k-400k req/sec
- **Latency**: 2-3ms p99
- **Coroutines**: Lightweight async operations

### Kotlin Advantages
- **Concise Syntax**: Less boilerplate than Java
- **Coroutines**: Async/await for non-blocking I/O
- **Type Safety**: Compile-time error checking
- **JVM Ecosystem**: Access to all Java libraries

## 🔧 Configuration

### Database Connection Pool
```kotlin
// HikariCP configuration
val config = HikariConfig().apply {
    jdbcUrl = dbUrl
    maximumPoolSize = 25
    minimumIdle = 5
}
```

### Redis Connection
```kotlin
// Lettuce client
val redisClient = RedisClient.create(redisUrl)
val connection = redisClient.connect()
```

## 📦 Dependencies

### Core
- `io.ktor:ktor-server-core-jvm` - Ktor core
- `io.ktor:ktor-server-netty-jvm` - Netty server
- `io.ktor:ktor-server-content-negotiation-jvm` - Content negotiation

### Database
- `org.postgresql:postgresql` - PostgreSQL driver
- `com.zaxxer:HikariCP` - Connection pooling

### Cache
- `io.lettuce:lettuce-core` - Redis client

### Serialization
- `kotlinx-serialization-json` - JSON serialization
- `kotlinx-coroutines-core` - Coroutines

## 🐳 Kubernetes

Deploy with:
```bash
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Port-forward:
```bash
kubectl port-forward svc/kotlin-ktor 8080:80
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
src/kotlin/ktor/
├── build.gradle.kts                    # Gradle configuration
├── Dockerfile                           # Multi-stage build
├── docker-compose.yml                  # Local orchestration
├── build.sh                            # Build automation
├── run.sh                              # Run automation
├── .env.example                        # Environment template
├── .gitignore                          # Git ignore rules
├── README.md                           # This file
├── src/main/kotlin/com/benchmark/
│   ├── Application.kt                  # Application entry point
│   ├── models/                         # Data models
│   ├── services/                       # Business logic
│   ├── routes/                         # HTTP routes
│   └── plugins/                        # Ktor plugins
└── k8s/
    ├── deployment.yaml                 # K8s deployment
    ├── service.yaml                    # K8s service
    └── configmap.yaml                  # K8s config
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
./build.sh {local|docker|clean|test|fatJar|docker-push|install-deps}
```

### Run Modes
```bash
./run.sh {dev|prod|docker}
```

### Gradle Tasks
```bash
gradle build           # Build project
gradle test            # Run tests
gradle clean           # Clean build
gradle fatJar          # Build fat JAR
```

## 📈 Expected Performance

Based on Kotlin/JVM benchmarks:
- **Throughput**: 300k-400k req/sec
- **Latency**: 2-3ms p99
- **Memory**: 100-200 MB
- **Startup**: 2-3 seconds

## ❌ Troubleshooting

### Build Errors
```bash
# Clean and rebuild
./build.sh clean
./build.sh local

# Check Java version
java -version
```

### Connection Errors
```bash
# Test PostgreSQL
psql "jdbc:postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"

# Test Redis
redis-cli -h redis.home.arpa -p 30379 -a Admin@123 PING
```

## 📚 Documentation

- [Ktor Guide](https://ktor.io/docs/)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [HikariCP](https://github.com/brettwooldridge/HikariCP)
- [Lettuce Redis](https://lettuce.io/)

## 📝 License

MIT

---

**Status**: ✅ Ready for deploy
**Image**: `benchmark/kotlin-ktor:latest`
**Performance**: ⭐⭐⭐⭐ Very Good
