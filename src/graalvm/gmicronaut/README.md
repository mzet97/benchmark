# Micronaut Native on GraalVM

High-performance REST API benchmark using Micronaut compiled as a GraalVM native image for instant startup and low memory footprint.

## Tech Stack

- Java 21 (GraalVM Community Edition)
- Micronaut 4.5.0 (native image)
- Micronaut Data JDBC + PostgreSQL
- Micronaut Redis (Lettuce)
- Maven build system with native-image packaging

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
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379` |
| `DB_USERNAME` | Database username | `app` |
| `DB_PASSWORD` | Database password | (none) |

## Build and Run

### Docker

```bash
./run.sh
```

### Manual

```bash
docker build -t benchmark-graalvm-gmicronaut .
docker run -p 3000:3000 \
    -e DATABASE_URL="jdbc:postgresql://host:5432/benchmark_api" \
    -e REDIS_URL="redis://host:6379" \
    benchmark-graalvm-gmicronaut
```

### Local Development

```bash
mvn package -Dpackaging=native-image -DskipTests
./target/benchmark-graalvm-micronaut
```
