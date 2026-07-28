# Helidon on GraalVM

High-performance REST API benchmark using Helidon SE running on GraalVM JDK 21.

## Tech Stack

- Java 21 (GraalVM Community Edition)
- Helidon SE 4.0.8
- HikariCP + PostgreSQL
- Jedis (Redis client)
- Maven build system

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root status check |
| GET | `/health` | Health check with DB and cache status |
| GET | `/healthz` | Simple liveness probe |
| GET | `/json` | JSON serialization benchmark (1000 items) |
| GET | `/db/simple?id=N` | Single database lookup |
| GET | `/db/complex?days=N` | Complex aggregation query |
| GET | `/cache?key=K` | Redis cache read/write |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/benchmark_api` |
| `DB_USERNAME` | Database username | `app` |
| `DB_PASSWORD` | Database password | (none) |
| `REDIS_URL` | Redis connection URL (host:port:password) | `localhost:6379:` |

## Build and Run

### Docker

```bash
./run.sh
```

### Manual

```bash
docker build -t benchmark-graalvm-helidon .
docker run -p 3000:3000 \
    -e DATABASE_URL="jdbc:postgresql://host:5432/benchmark_api" \
    -e DB_USERNAME="app" \
    -e DB_PASSWORD="secret" \
    -e REDIS_URL="host:6379:password" \
    benchmark-graalvm-helidon
```

### Local Development

```bash
mvn package -DskipTests
java -jar target/benchmark-helidon-1.0.0.jar
```
