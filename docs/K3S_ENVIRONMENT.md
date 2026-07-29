# K3s Environment

**Status**: TEMPLATE — Needs actual cluster data collection

## How to Collect

Run these commands against the K3s cluster and fill in the values:

```bash
# Cluster info
kubectl version
kubectl cluster-info
kubectl get nodes -o wide
kubectl describe nodes

# Resources
kubectl top nodes
kubectl get pods -A -o wide
kubectl get svc -A
kubectl get storageclass

# Health
kubectl get --raw /readyz

# Namespace
kubectl get all -n benchmark
kubectl get secrets -n benchmark
kubectl get configmaps -n benchmark
```

## Cluster Information

| Item | Value |
|------|-------|
| K3s Version | `______` |
| Kubernetes Version | `______` |
| Number of Nodes | `______` |
| Architecture | `______` |
| CNI | flannel (default) |
| CoreDNS | Built-in |
| kube-proxy | Built-in |
| Traefik | Built-in |
| ServiceLB | Built-in |
| metrics-server | `______` |

## Nodes

| Node | Role | CPU | Memory | Architecture | Labels |
|------|------|-----|--------|--------------|--------|
| `______` | `______` | `______` | `______` | `______` | `______` |
| `______` | `______` | `______` | `______` | `______` | `______` |

### Required Labels

```bash
# Label nodes for benchmark roles
kubectl label node <node-name> benchmark-role=server
kubectl label node <node-name> benchmark-role=loadgen
```

## Image Registry

| Strategy | Status |
|----------|--------|
| Harbor/private registry | `______` |
| Docker Hub | `______` |
| GHCR | `______` |
| Local registry | `______` |
| containerd import | `______` |

## External Services

### PostgreSQL

| Item | Value |
|------|-------|
| Host | `spsql.home.arpa` |
| Port | `5432` |
| Database | `benchmark_api` |
| Users table | 10,000 rows |
| Orders table | 50,000 rows |
| Order items table | 200,000 rows |

### Redis

| Item | Value |
|------|-------|
| Host | `redis.home.arpa` |
| Port | `30379` |

## Capacity

| Resource | Total | Used | Available |
|----------|-------|------|-----------|
| CPU (cores) | `______` | `______` | `______` |
| Memory (GB) | `______` | `______` | `______` |
| Pods | `______` | `______` | `______` |

## Active Workloads

List any workloads running in the cluster that might affect benchmark results:

| Namespace | Workload | Impact |
|-----------|----------|--------|
| `______` | `______` | `______` |

---

**Last Updated**: 2026-07-29
**Status**: TEMPLATE — Fill with actual cluster data
