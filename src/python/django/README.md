# Python Django - Benchmark API

REST API benchmark implementation using Python with Django REST Framework.

## Tech Stack

- **Runtime**: Python 3.12
- **Framework**: Django 5.1 + Django REST Framework
- **Database**: PostgreSQL (psycopg2-binary)
- **Cache**: Redis (redis-py)
- **Server**: Gunicorn (4 workers, 2 threads)

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
docker run -p 8000:8000 benchmark/python-django:latest

# Kubernetes
kubectl apply -f k8s/ -n benchmark
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api` | PostgreSQL connection string |
| `REDIS_URL` | `redis://:Admin@123@redis.home.arpa:30379` | Redis connection string |
| `PORT` | `8000` | Server port |
| `DEBUG` | `False` | Debug mode |

## Benchmark

```bash
./scripts/benchmark-wrk-python.sh
```
