# Deno Hono - Benchmark API

REST API benchmark implementation using Deno with Hono framework.

## Tech Stack

- **Runtime**: Deno 2.0
- **Framework**: Hono 4.x
- **Database**: PostgreSQL (deno-postgres)
- **Cache**: Redis (deno-redis)

## Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check (DB + Redis) |
| `GET /healthz` | Kubernetes liveness probe |
| `GET /json` | JSON serialization (1000 objects) |
| `GET /db/simple?id={id}` | Simple DB query (user by ID) |
| `GET /db/complex?days={days}` | Complex DB query (JOIN + aggregation) |
| `GET /cache?key={key}` | Redis cache get/set |

## Build & Run

```bash
# Local
./build.sh local
./run.sh

# Docker
./build.sh docker
docker run -p 3000:3000 benchmark/deno-hono:latest

# Kubernetes
kubectl apply -f k8s/ -n benchmark
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api` | PostgreSQL connection string |
| `REDIS_URL` | `redis://:${REDIS_PASSWORD}@redis.home.arpa:30379` | Redis connection string |
| `PORT` | `3000` | Server port |
