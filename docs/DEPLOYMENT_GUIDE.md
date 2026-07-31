# Deployment Guide

## Overview

Complete guide for deploying all 11 benchmark implementations across different environments.

## Prerequisites

### Required Tools
- Docker 20.10+
- Kubernetes 1.28+ (kubectl)
- PostgreSQL client (psql)
- Redis client (redis-cli)

### Language-Specific Tools (as needed)
- .NET 9 SDK (C#)
- Rust toolchain (Rust)
- Java 21+ / Maven (Java, GraalVM)
- Go 1.23+ (Go)
- Kotlin / Gradle (Kotlin)
- Node.js 22+ (Node.js)
- Python 3.12+ (Python)
- Bun 1.x (Bun)
- Deno 2.x (Deno)
- Dart 3.x (Dart)

### Optional Tools
- k6 (benchmarks)
- wrk (benchmarks)
- Helm (se usando charts)
- Docker Registry (para push de imagens)

### Infrastructure
- PostgreSQL: `spsql.home.arpa:5432`
- Redis: `redis.home.arpa:30379`
- Kubernetes cluster com acesso aos hosts acima

## Supported Languages

| Language | Framework | Source Path | Build Tool |
|----------|-----------|-------------|------------|
| C# (.NET 9) | Minimal API | `src/csharp/MinimalApi/` | dotnet |
| Rust | Actix Web | `src/rust/actix-web/` | cargo |
| Java | Quarkus | `src/java/quarkus/` | maven |
| Go | Fiber | `src/go/fiber/` | go build |
| Kotlin | Ktor | `src/kotlin/ktor/` | gradle |
| Node.js | Fastify | `src/nodejs/fastify/` | npm |
| Python | FastAPI | `src/python/fastapi/` | pip |
| Bun | Elysia | `src/bun/elysia/` | bun |
| Deno | Oak | `src/deno/oak/` | deno |
| Dart | Shelf | `src/dart/vaden/` | dart |
| GraalVM | Vert.x | `src/graalvm/vertx/` | maven |

## Deployment Methods

### 1. Local Development

Each language has its own build and run process. Use the `build.sh` script in each directory:

```bash
# C#
cd src/csharp/MinimalApi
./build.sh
./build.sh run

# Rust
cd src/rust/actix-web
./build.sh
./build.sh run

# Java
cd src/java/quarkus
./build.sh
./build.sh run

# Go
cd src/go/fiber
./build.sh
./build.sh run

# Kotlin
cd src/kotlin/ktor
./build.sh
./build.sh run

# Node.js
cd src/nodejs/fastify
./build.sh
./build.sh run

# Python
cd src/python/fastapi
./build.sh
./build.sh run

# Bun
cd src/bun/elysia
./build.sh
./build.sh run

# Deno
cd src/deno/oak
./build.sh
./build.sh run

# Dart
cd src/dart/vaden
./build.sh
./build.sh run

# GraalVM
cd src/graalvm/vertx
./build.sh
./build.sh run
```

#### Test Endpoints (all languages)
```bash
# Health check
curl http://localhost:8080/health

# JSON endpoint
curl http://localhost:8080/json | head -20

# Database query
curl http://localhost:8080/db/simple?id=1

# Complex query
curl http://localhost:8080/db/complex?days=30

# Cache
curl http://localhost:8080/cache?key=test
```

### 2. Docker Deployment

Each implementation includes a Dockerfile with multi-stage builds:

```bash
# Build any language image
cd src/<language>/<framework>
docker build -t benchmark/<language>-<framework>:latest .

# Examples:
cd src/csharp/MinimalApi && docker build -t benchmark/csharp-minimalapi:latest .
cd src/rust/actix-web && docker build -t benchmark/rust-actix:latest .
cd src/java/quarkus && docker build -t benchmark/java-quarkus:latest .
cd src/go/fiber && docker build -t benchmark/go-fiber:latest .
cd src/kotlin/ktor && docker build -t benchmark/kotlin-ktor:latest .
cd src/nodejs/fastify && docker build -t benchmark/nodejs-fastify:latest .
cd src/python/fastapi && docker build -t benchmark/python-fastapi:latest .
cd src/bun/elysia && docker build -t benchmark/bun-elysia:latest .
cd src/deno/oak && docker build -t benchmark/deno-oak:latest .
cd src/dart/vaden && docker build -t benchmark/dart-shelf:latest .
cd src/graalvm/vertx && docker build -t benchmark/graalvm-vertx:latest .
```

#### Run Container (generic)
```bash
docker run -d \
  --name <language>-api \
  -p 8080:8080 \
  -e DATABASE_URL="postgresql://app:${DB_PASSWORD}@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:${REDIS_PASSWORD}@redis.home.arpa:30379" \
  benchmark/<language>-<framework>:latest

# Check logs
docker logs -f <language>-api

# Test
curl http://localhost:8080/health

# Stop and remove
docker stop <language>-api
docker rm <language>-api
```

### 3. Kubernetes Deployment

#### Prerequisites
```bash
# Verify cluster access
kubectl cluster-info
kubectl get nodes

# Create namespace
kubectl create namespace benchmark
```

#### Deploy Any Language
```bash
# Apply all manifests for a language
kubectl apply -f src/<language>/<framework>/k8s/ -n benchmark

# Examples:
kubectl apply -f src/csharp/MinimalApi/k8s/ -n benchmark
kubectl apply -f src/rust/actix-web/k8s/ -n benchmark
kubectl apply -f src/java/quarkus/k8s/ -n benchmark
kubectl apply -f src/go/fiber/k8s/ -n benchmark
kubectl apply -f src/kotlin/ktor/k8s/ -n benchmark
kubectl apply -f src/nodejs/fastify/k8s/ -n benchmark
kubectl apply -f src/python/fastapi/k8s/ -n benchmark
kubectl apply -f src/bun/elysia/k8s/ -n benchmark
kubectl apply -f src/deno/oak/k8s/ -n benchmark
kubectl apply -f src/dart/vaden/k8s/ -n benchmark
kubectl apply -f src/graalvm/vertx/k8s/ -n benchmark
```

#### Check Status
```bash
# Pods status
kubectl get pods -n benchmark

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=<language>-<framework> --timeout=120s -n benchmark

# Describe pod (detailed info)
kubectl describe pod -l app=<language>-<framework> -n benchmark

# View logs
kubectl logs -l app=<language>-<framework> -n benchmark --tail=100
```

#### Test Service
```bash
# Port-forward for local testing
kubectl port-forward -n benchmark svc/<language>-<framework> 8080:80

# Test endpoints
curl http://localhost:8080/health
```

#### Remove Deployment
```bash
# Delete all resources for a language
kubectl delete -f src/<language>/<framework>/k8s/ -n benchmark

# Delete all benchmark resources
kubectl delete namespace benchmark
```

### 4. CI/CD Pipeline (GitHub Actions)

#### Example Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy Benchmark API

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        language: [csharp, rust, java, go, kotlin, nodejs, python, bun, deno, dart, graalvm]
    steps:
      - uses: actions/checkout@v3

      - name: Build Application
        run: |
          cd src/${{ matrix.language }}/*
          ./build.sh docker

      - name: Push to Registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push benchmark/${{ matrix.language }}:latest

      - name: Deploy to Kubernetes
        run: |
          echo ${{ secrets.KUBE_CONFIG }} | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          kubectl apply -f src/${{ matrix.language }}/*/k8s/ -n benchmark
```

## Monitoring

### Prometheus Integration

Add annotations to deployment:
```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

### Grafana Dashboard

Import dashboard for:
- Request rate
- Latency (p50, p95, p99)
- Error rate
- CPU/Memory usage

### Logging

#### Structured Logs
All services log in JSON format:
```json
{
  "timestamp": "2026-07-27T10:00:00.000Z",
  "level": "INFO",
  "message": "Request completed",
  "requestId": "req-123",
  "method": "GET",
  "path": "/db/simple",
  "statusCode": 200,
  "durationMs": 12.5
}
```

#### Centralized Logging
Deploy ELK or Loki stack for log aggregation.

### Health Checks

#### Kubernetes Health Checks
Already configured in all deployments:
- **Liveness Probe**: `/health` every 10s
- **Readiness Probe**: `/health` every 5s
- **Startup Probe**: `/health` (30s initial delay)

#### Custom Health Checks
```bash
# Check database connectivity
curl http://localhost:8080/health | jq

# Detailed health (development)
curl http://localhost:8080/healthz | jq
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Failed
```bash
# Check database connectivity
psql -h spsql.home.arpa -p 5432 -U app -d benchmark_api -c "SELECT 1;"

# View logs
kubectl logs -l app=<language>-<framework> -n benchmark | grep -i "database\|connection"
```

#### 2. Redis Connection Failed
```bash
# Check Redis connectivity
redis-cli -h redis.home.arpa -p 30379 -a <REDACTED> ping

# View logs
kubectl logs -l app=<language>-<framework> -n benchmark | grep -i "redis"
```

#### 3. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n benchmark

# Check events
kubectl get events -n benchmark --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod <pod-name> -n benchmark

# Check image pull
kubectl get events -n benchmark | grep "Failed to pull image"
```

#### 4. High Latency
```bash
# Check resource usage
kubectl top pods -n benchmark

# Check resource limits
kubectl describe deployment <language>-<framework> -n benchmark
```

#### 5. OutOfMemory
```bash
# Check memory usage
kubectl top pods -n benchmark

# Increase memory limits
kubectl patch deployment <language>-<framework> -n benchmark -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Check for memory leaks
kubectl describe pod <pod-name> -n benchmark | grep -A 5 "Last State"
```

### Debugging Commands

```bash
# Get all resources
kubectl get all -n benchmark

# View config
kubectl get configmap -n benchmark -o yaml

# Exec into pod
kubectl exec -it <pod-name> -n benchmark -- sh

# Network debugging
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- sh
# Inside debug pod:
nslookup spsql.home.arpa
nc -zv spsql.home.arpa 5432
nc -zv redis.home.arpa 30379
```

## Performance Tuning

### Database Connection Pool
Default: 25 connections per language

Adjust per language in configuration files.

### Redis Configuration
Default TTL: 5 minutes

### Kubernetes Resources
Default:
- Requests: 128Mi memory, 100m CPU
- Limits: 512Mi memory, 500m CPU

Adjust in `deployment.yaml`:
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Native AOT Optimization (C# / GraalVM)

For C# with Native AOT, the `.csproj` uses:
```xml
<PublishAot>true</PublishAot>
<PublishTrimmed>false</PublishTrimmed>
<InvariantGlobalization>true</InvariantGlobalization>
```

For GraalVM with native image:
```xml
<quarkus.native.enabled>true</quarkus.native.enabled>
<quarkus.native.container-build>true</quarkus.native.container-build>
```

## Security

### Best Practices (all languages)
- Non-root user (UID 1001)
- Read-only root filesystem
- No privilege escalation
- Dropped all capabilities
- Health checks configured
- Resource limits set

### Secrets Management
Currently using ConfigMap for passwords (development only).

For production:
```yaml
# Use Kubernetes Secrets
apiVersion: v1
kind: Secret
metadata:
  name: benchmark-secrets
type: Opaque
stringData:
  database-password: "<REDACTED>"
  redis-password: "<REDACTED>"
```

## Backup and Recovery

### Database Backup
```bash
# Backup
pg_dump -h spsql.home.arpa -U app benchmark_api > backup.sql

# Restore
psql -h spsql.home.arpa -U app benchmark_api < backup.sql
```

### Application State
All applications are stateless - no backup needed.

## Cost Optimization

### Resource Sizing
- Development: 5 replicas, 128Mi-512Mi
- Production: Adjust based on load testing

### Auto-scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: benchmark-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <language>-<framework>
  minReplicas: 5
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## Next Steps

All 11 implementations are complete and deployed:

1. C# (.NET 9) - Complete
2. Rust (Actix Web) - Complete
3. Java (Quarkus) - Complete
4. Go (Fiber) - Complete
5. Kotlin (Ktor) - Complete
6. Node.js (Fastify) - Complete
7. Python (FastAPI) - Complete
8. Bun (Elysia) - Complete
9. Deno (Oak) - Complete
10. Dart (Shelf) - Complete
11. GraalVM (Vert.x) - Complete

**Next**: Run full benchmark suite across all implementations.

## Support

For issues or questions:
1. Check logs: `kubectl logs -l app=<language>-<framework> -n benchmark`
2. Check events: `kubectl get events -n benchmark`
3. Review this guide
4. Open an issue

---

**Last Updated**: 2026-07-27
**Status**: All 11 implementations complete
