# Reproducibility

## Requirements

To reproduce this benchmark, you need:

### Infrastructure

- **K3s cluster** with at least 2 nodes (1 server + 1 loadgen)
- **PostgreSQL** accessible at `spsql.home.arpa:5432`
- **Redis** accessible at `redis.home.arpa:30379`
- **Docker** for building images
- **kubectl** configured for the cluster

### Software

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24+ | Build images |
| kubectl | 1.28+ | Kubernetes management |
| Kustomize | 5+ | Manifest management |
| git | 2.x | Source control |
| make | 4.x | Automation |
| wrk | 4.x | REST load testing |
| k6 | 0.47+ | REST/GraphQL load testing |
| ghz | 0.100+ | gRPC load testing |
| grpcurl | 1.8+ | gRPC smoke testing |

## Steps

### 1. Clone Repository

```bash
git clone https://github.com/mzet97/benchmark.git
cd benchmark
```

### 2. Setup Database

```bash
make setup-database
```

This runs `sql/01_schema.sql`, `sql/02_seed.sql`, `sql/03_indexes.sql`.

### 3. Create Kubernetes Secrets

```bash
kubectl create namespace benchmark
kubectl create secret generic benchmark-secrets \
  --namespace benchmark \
  --from-literal=database-url="postgresql://app:<PASSWORD>@spsql.home.arpa:5432/benchmark_api" \
  --from-literal=redis-url="redis://:<PASSWORD>@redis.home.arpa:30379"
```

### 4. Label Nodes

```bash
kubectl label node <server-node> benchmark-role=server
kubectl label node <loadgen-node> benchmark-role=loadgen
```

### 5. Build Images

```bash
# Single implementation
make build IMPL=rust-rest-actix-web

# All REST
for impl in rust-rest-actix-web rust-rest-axum rust-rest-rocket; do
  make build IMPL=$impl
done
```

### 6. Run Preflight

```bash
make preflight
```

Validates PostgreSQL and Redis connectivity from inside the cluster.

### 7. Deploy and Benchmark

```bash
# Deploy
make deploy IMPL=rust-rest-actix-web MODE=single-pod

# Smoke test
make smoke IMPL=rust-rest-actix-web

# Benchmark (manual for now)
# wrk, k6, or ghz commands

# Undeploy
make undeploy IMPL=rust-rest-actix-web
```

### 8. Repeat for All Implementations

Follow the methodology in `docs/BENCHMARK_METHODOLOGY.md`:
- One implementation at a time
- 5 repetitions per combination
- Randomized order
- 30s warm-up, 60s measurement

## Environment Snapshot

Record these for each benchmark run:

```bash
# Git commit
git rev-parse HEAD

# K3s version
kubectl version --short

# Kernel
uname -a

# CPU frequency
cat /proc/cpuinfo | grep "cpu MHz"

# Load average
uptime

# Node info
kubectl get nodes -o wide
```

## Expected Results

Results will vary based on:
- Hardware (CPU, memory, disk)
- Network topology
- K3s version
- Concurrent workloads
- CPU governor settings

Use the **standard resource profile** (1 CPU, 512Mi) for comparable results.

## Troubleshooting

### Image not found

```bash
# Check if image exists in containerd
sudo crictl images | grep benchmark

# Import image manually
docker save benchmark/rust-rest-actix-web:latest | sudo ctr -n k8s.io images import -
```

### Pod not scheduling

```bash
# Check node labels
kubectl get nodes --show-labels

# Check taints
kubectl describe nodes | grep Taints

# Check resources
kubectl top nodes
```

### Database connection failed

```bash
# Test from inside cluster
kubectl run -it --rm debug --image=postgres:16-alpine --restart=Never -- \
  psql -h spsql.home.arpa -U app -d benchmark_api -c "SELECT 1;"
```

---

**Last Updated**: 2026-07-29
