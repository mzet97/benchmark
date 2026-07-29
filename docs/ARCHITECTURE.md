# Architecture

## Overview

This benchmark project evaluates **101 API implementations** across **11 technology environments** and **3 protocols** (REST, gRPC, GraphQL) on a **K3s Kubernetes cluster**.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    K3s Cluster                               │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │  Node 1      │    │  Node 2      │    │  Node 3      │   │
│  │  (server)    │    │  (worker)    │    │  (loadgen)   │   │
│  │              │    │              │    │              │   │
│  │  ┌────────┐  │    │  ┌────────┐  │    │  ┌────────┐  │   │
│  │  │ App Pod│  │    │  │ App Pod│  │    │  │ wrk/k6 │  │   │
│  │  │ (REST) │◄─┼────┼──┤ (gRPC) │  │    │  │ ghz    │  │   │
│  │  │        │  │    │  │        │  │    │  │        │  │   │
│  │  └───┬────┘  │    │  └───┬────┘  │    │  └───┬────┘  │   │
│  │      │       │    │      │       │    │      │       │   │
│  └──────┼───────┘    └──────┼───────┘    └──────┼───────┘   │
│         │                   │                   │            │
│         ▼                   ▼                   │            │
│  ┌──────────────────────────────────┐           │            │
│  │        ClusterIP Service         │◄──────────┘            │
│  │    (kube-proxy + CoreDNS)        │                        │
│  └──────────────────────────────────┘                        │
│                                                              │
│  ┌──────────────┐              ┌──────────────┐              │
│  │ PostgreSQL   │              │ Redis        │              │
│  │ (external)   │              │ (external)   │              │
│  │ spsql.home   │              │ redis.home   │              │
│  └──────────────┘              └──────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### REST

```
Client → TCP → kube-proxy → Pod → HTTP Handler → Response
```

### gRPC

```
Client → HTTP/2 → kube-proxy → Pod → gRPC Handler → Protobuf Response
```

### GraphQL

```
Client → HTTP POST /graphql → kube-proxy → Pod → GraphQL Engine → JSON Response
```

## Component Layers

### 1. Load Generator Layer

| Tool | Protocol | Location |
|------|----------|----------|
| wrk | REST | `deploy/k3s/loadgen/job-wrk.yaml` |
| k6 | REST/GraphQL | `deploy/k3s/loadgen/` |
| ghz | gRPC | `deploy/k3s/loadgen/job-ghz.yaml` |

All load generators run as **Kubernetes Jobs** inside the cluster, scheduled on a node with label `benchmark-role=loadgen`.

### 2. Application Layer

Each implementation follows this pattern:

```
┌─────────────────────────────────┐
│         HTTP/gRPC Server        │
│  (Framework-specific handler)   │
├─────────────────────────────────┤
│         Business Logic          │
│  (5 benchmark scenarios)        │
├─────────────┬───────────────────┤
│  PostgreSQL │  Redis            │
│  Service    │  Service          │
└─────────────┴───────────────────┘
```

### 3. Data Layer

**PostgreSQL** (`spsql.home.arpa:5432`)
- Database: `benchmark_api`
- Tables: `users` (10k), `orders` (50k), `order_items` (200k)
- Connection pooling: per-implementation

**Redis** (`redis.home.arpa:30379`)
- Used for cache hit/miss scenario
- TTL: 300 seconds (configurable)

### 4. Infrastructure Layer

**K3s** provides:
- Container runtime (containerd)
- Networking (flannel)
- Service discovery (CoreDNS)
- Load balancing (kube-proxy)
- Ingress (Traefik — not used in primary benchmark)

## Deployment Modes

### Mode A — Pod Single Direct

```
LoadGen → Pod IP (direct)
```

- 1 replica
- Direct pod access (headless service)
- Minimal Kubernetes overhead
- **Primary ranking mode**

### Mode B — ClusterIP Single

```
LoadGen → Service ClusterIP → Pod
```

- 1 replica
- Service + CoreDNS + kube-proxy overhead measured

### Mode C — ClusterIP Scale-Out

```
LoadGen → Service ClusterIP → Pod 1
                             → Pod 2
                             → Pod 3
                             → Pod 4
                             → Pod 5
```

- 5 replicas
- Load distribution measured
- Aggregate throughput

## Resource Profiles

```yaml
standard:
  requests: { cpu: "1", memory: "512Mi" }
  limits:   { cpu: "1", memory: "512Mi" }

small:
  requests: { cpu: "500m", memory: "256Mi" }
  limits:   { cpu: "500m", memory: "256Mi" }

scale-out:
  requests: { cpu: "500m", memory: "256Mi" }
  limits:   { cpu: "1", memory: "512Mi" }
```

## Image Management

Images use immutable tags:

```
<registry>/benchmark/<implementation-id>:<git-sha>
<registry>/benchmark/<implementation-id>:latest  # convenience
```

Build: `scripts/build-image.sh <impl-id>`
Push: `docker push <registry>/benchmark/<impl-id>:<sha>`

## Configuration Management

| File | Purpose |
|------|---------|
| `config/implementations.yaml` | Source of truth for all 101 implementations |
| `kubernetes/secrets.example.yaml` | Secret template (no real credentials) |
| `deploy/k3s/base/` | Kustomize base templates |
| `deploy/k3s/overlays/` | Per-implementation overlays |

## Observability

### Metrics Collected

| Category | Metrics |
|----------|---------|
| Latency | p50, p90, p95, p99, p99.9, max |
| Throughput | Requests/sec, operations/sec |
| Errors | Error rate, timeouts |
| Resources | CPU mean/max, RSS mean/max, network I/O |
| Kubernetes | Pod restarts, OOM kills, scheduling info |

### Output Format

JSON per run (see `docs/RESULTS_SCHEMA.md`).

---

**Last Updated**: 2026-07-29
