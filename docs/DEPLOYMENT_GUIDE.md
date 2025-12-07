# Deployment Guide

## Overview

Guia completo para deploy das implementações em diferentes ambientes.

## Prerequisites

### Required Tools
- Docker 20.10+
- Kubernetes 1.28+ (kubectl)
- .NET 9 SDK (para build local)
- PostgreSQL client (psql)
- Redis client (redis-cli)

### Optional Tools
- k6 (benchmarks)
- wrk (benchmarks)
- Helm (se usando charts)
- Docker Registry (para push de imagens)

### Infrastructure
- PostgreSQL: `spsql.home.arpa:5432`
- Redis: `redis.home.arpa:30379`
- Kubernetes cluster com acesso aos hosts acima

## Deployment Methods

### 1. Local Development

#### Build and Run
```bash
# Build C# application
cd src/csharp/MinimalApi
dotnet restore
dotnet build -c Release

# Publish com Native AOT
dotnet publish -c Release -o ./publish \
    -p:PublishAot=true \
    -p:PublishSingleFile=true

# Run locally
./publish/benchmark-api --urls "http://localhost:8080"
```

#### Test Endpoints
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

#### Build Image
```bash
# Build C# image
cd src/csharp/MinimalApi
docker build -t benchmark/csharp-minimalapi:latest .

# Verify image
docker images benchmark/csharp-minimalapi

# Check image size
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" benchmark/csharp-minimalapi
```

#### Run Container
```bash
# Run with environment variables
docker run -d \
  --name csharp-api \
  -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="Host=spsql.home.arpa;Port=5432;Database=benchmark_api;Username=app;Password=Admin@123;Maximum Pool Size=25;Connection Timeout=30;" \
  -e Redis__ConnectionString="redis.home.arpa:30379,password=Admin@123,defaultDatabase=0,ssl=false" \
  benchmark/csharp-minimalapi:latest

# Check logs
docker logs -f csharp-api

# Test
curl http://localhost:8080/health

# Stop and remove
docker stop csharp-api
docker rm csharp-api
```

#### Docker Compose (Development)
```yaml
# docker-compose.yml
version: '3.8'

services:
  csharp-api:
    build:
      context: ./src/csharp/MinimalApi
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - ConnectionStrings__DefaultConnection=Host=spsql.home.arpa;Port=5432;Database=benchmark_api;Username=app;Password=Admin@123;Maximum Pool Size=25;Connection Timeout=30;
      - Redis__ConnectionString=redis.home.arpa:30379,password=Admin@123,defaultDatabase=0,ssl=false
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

Run with:
```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
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

#### Deploy C# Application
```bash
# Apply ConfigMap
kubectl apply -f src/csharp/MinimalApi/k8s/configmap.yaml

# Apply Deployment
kubectl apply -f src/csharp/MinimalApi/k8s/deployment.yaml

# Apply Service
kubectl apply -f src/csharp/MinimalApi/k8s/service.yaml

# Verify deployment
kubectl get all -n benchmark -l app=csharp-minimalapi
```

#### Check Status
```bash
# Pods status
kubectl get pods -n benchmark -l app=csharp-minimalapi

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=csharp-minimalapi --timeout=120s -n benchmark

# Describe pod (detailed info)
kubectl describe pod -l app=csharp-minimalapi -n benchmark

# View logs
kubectl logs -l app=csharp-minimalapi -n benchmark --tail=100

# Follow logs
kubectl logs -l app=csharp-minimalapi -n benchmark -f
```

#### Test Service
```bash
# Port-forward for local testing
kubectl port-forward -n benchmark svc/csharp-minimalapi 8080:80

# Test endpoints
curl http://localhost:8080/health

# Inside cluster (create temporary pod)
kubectl run -it --rm debug --image=curlimages/curl:latest --restart=Never -- sh
# Inside pod:
curl http://csharp-minimalapi.benchmark.svc.cluster.local/health
exit
```

#### Scale Deployment
```bash
# Scale to 10 replicas
kubectl scale deployment csharp-minimalapi --replicas=10 -n benchmark

# Verify
kubectl get pods -n benchmark -l app=csharp-minimalapi

# Auto-scaling (if metrics-server installed)
kubectl autoscale deployment csharp-minimalapi --min=5 --max=15 --cpu-percent=80 -n benchmark
```

#### Update Deployment
```bash
# Update image
kubectl set image deployment/csharp-minimalapi \
  api=benchmark/csharp-minimalapi:v1.1 \
  -n benchmark

# Watch rollout
kubectl rollout status deployment/csharp-minimalapi -n benchmark

# Rollback if needed
kubectl rollout undo deployment/csharp-minimalapi -n benchmark
```

#### Remove Deployment
```bash
# Delete all resources
kubectl delete -f src/csharp/MinimalApi/k8s/service.yaml
kubectl delete -f src/csharp/MinimalApi/k8s/deployment.yaml
kubectl delete -f src/csharp/MinimalApi/k8s/configmap.yaml

# Force delete pods (if stuck)
kubectl delete pods -l app=csharp-minimalapi -n benchmark --force

# Delete namespace
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
    steps:
      - uses: actions/checkout@v3

      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '9.0.x'

      - name: Build C# Application
        run: |
          cd src/csharp/MinimalApi
          dotnet restore
          dotnet build -c Release
          dotnet publish -c Release -o ./publish \
            -p:PublishAot=true \
            -p:PublishSingleFile=true

      - name: Build Docker Image
        run: |
          cd src/csharp/MinimalApi
          docker build -t benchmark/csharp-minimalapi:${{ github.sha }} .
          docker tag benchmark/csharp-minimalapi:${{ github.sha }} benchmark/csharp-minimalapi:latest

      - name: Push to Registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push benchmark/csharp-minimalapi:${{ github.sha }}
          docker push benchmark/csharp-minimalapi:latest

      - name: Deploy to Kubernetes
        run: |
          echo ${{ secrets.KUBE_CONFIG }} | base64 -d > kubeconfig
          export KUBECONFIG=kubeconfig
          kubectl set image deployment/csharp-minimalapi api=benchmark/csharp-minimalapi:${{ github.sha }} -n benchmark
          kubectl rollout status deployment/csharp-minimalapi -n benchmark
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
  "timestamp": "2025-12-07T10:00:00.000Z",
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
Already configured in deployment:
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

# Check connection string
echo $ConnectionStrings__DefaultConnection

# View logs
kubectl logs -l app=csharp-minimalapi -n benchmark | grep -i "database\|connection"
```

#### 2. Redis Connection Failed
```bash
# Check Redis connectivity
redis-cli -h redis.home.arpa -p 30379 -a Admin@123 ping

# Check connection string
echo $Redis__ConnectionString

# View logs
kubectl logs -l app=csharp-minimalapi -n benchmark | grep -i "redis"
```

#### 3. Pods Not Starting
```bash
# Check pod status
kubectl get pods -l app=csharp-minimalapi -n benchmark

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
kubectl top pods -n benchmark -l app=csharp-minimalapi

# Check resource limits
kubectl describe deployment csharp-minimalapi -n benchmark

# Check connection pool
# View application logs for pool metrics
```

#### 5. OutOfMemory
```bash
# Check memory usage
kubectl top pods -n benchmark -l app=csharp-minimalapi

# Increase memory limits
kubectl patch deployment csharp-minimalapi -n benchmark -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Check for memory leaks
kubectl describe pod <pod-name> -n benchmark | grep -A 5 "Last State"
```

### Debugging Commands

```bash
# Get all resources
kubectl get all -n benchmark -l app=csharp-minimalapi

# View config
kubectl get configmap csharp-minimalapi-config -n benchmark -o yaml

# Exec into pod
kubectl exec -it <pod-name> -n benchmark -- sh

# Inside pod, check:
ls -la
ps aux
cat /etc/resolv.conf
curl -v http://spsql.home.arpa:5432
curl -v http://redis.home.arpa:30379

# Network debugging
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- sh
# Inside debug pod:
nslookup spsql.home.arpa
dig spsql.home.arpa
nc -zv spsql.home.arpa 54379
nc -zv redis.home.arpa 30379
```

## Performance Tuning

### Database Connection Pool
Default: 25 connections

Adjust in `appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "...;Maximum Pool Size=100;..."
  }
}
```

### Redis Configuration
Default TTL: 5 minutes

Adjust in `CacheService.cs`:
```csharp
private readonly TimeSpan _defaultExpiry = TimeSpan.FromMinutes(10);
```

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

### Native AOT Optimization
Current settings in `.csproj`:
```xml
<PublishAot>true</PublishAot>
<PublishSingleFile>true</PublishSingleFile>
<PublishTrimmed>false</PublishTrimmed>
<EnableCompressionInSingleFile>true</EnableCompressionInSingleFile>
<InvariantGlobalization>true</InvariantGlobalization>
```

## Security

### Best Practices
- ✅ Non-root user (UID 1001)
- ✅ Read-only root filesystem
- ✅ No privilege escalation
- ✅ Dropped all capabilities
- ✅ Health checks configured
- ✅ Resource limits set

### Secrets Management
Currently using ConfigMap for passwords (development only).

For production:
```yaml
# Use Kubernetes Secrets
apiVersion: v1
kind: Secret
metadata:
  name: csharp-minimalapi-secrets
type: Opaque
stringData:
  database-password: "Admin@123"
  redis-password: "Admin@123"

# Reference in deployment
env:
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: csharp-minimalapi-secrets
      key: database-password
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
Stateless application - no backup needed.

## Cost Optimization

### Resource Sizing
- Development: 5 replicas, 128Mi-512Mi
- Production: Adjust based on load testing

### Auto-scaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: csharp-minimalapi-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: csharp-minimalapi
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

1. ✅ Deploy C# (.NET 9)
2. 🔄 Deploy Rust (Actix Web)
3. 📋 Deploy Java (Quarkus)
4. 📋 Deploy Go (Fiber)
5. 📋 Deploy all other languages

## Support

For issues or questions:
1. Check logs: `kubectl logs -l app=csharp-minimalapi -n benchmark`
2. Check events: `kubectl get events -n benchmark`
3. Review this guide
4. Open an issue
