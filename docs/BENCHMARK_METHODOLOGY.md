# Benchmark Methodology

## Overview

This document describes the scientific methodology used for all benchmark tests.

## Test Modes

### Mode A — Pod Single Direct

- **Goal**: Measure framework performance with minimal Kubernetes interference
- **Replicas**: 1
- **Access**: Direct pod IP or headless service
- **Resources**: Fixed (standard profile)
- **No Ingress**: No load balancer, no proxy
- **Isolation**: No other benchmark implementation active

This is the **primary result** for framework-to-framework comparison.

### Mode B — ClusterIP Single Replica

- **Goal**: Measure additional cost of Service, CoreDNS, kube-proxy
- **Replicas**: 1
- **Access**: ClusterIP Service
- **Resources**: Same as Mode A

### Mode C — ClusterIP Scale-Out (5 replicas)

- **Goal**: Measure horizontal scalability and load balancing
- **Replicas**: 5
- **Access**: ClusterIP Service
- **Pod distribution**: Recorded per node
- **Metrics**: Aggregate throughput + per-pod consumption

Results from Mode A, B, and C are **never mixed** in rankings.

## Resource Profiles

### Standard (default for ranking)

```yaml
resources:
  requests:
    cpu: "1"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

### Small

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

### Unlimited Diagnostic

```yaml
resources:
  requests:
    cpu: "2"
    memory: "1Gi"
  limits:
    cpu: "4"
    memory: "2Gi"
```

### Scale-Out

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

## Test Execution Protocol

For each implementation × scenario × mode combination:

1. Remove previous implementation
2. Confirm no competing pods
3. Deploy implementation
4. Wait for readiness
5. Run smoke test
6. Warm-up: 30 seconds
7. Wait for stabilization: 10 seconds
8. Run 5 measurement repetitions (60s each)
9. Collect metrics
10. Remove implementation
11. Wait for cluster stabilization: 10 seconds
12. Run next combination

### Randomization

Implementation order is **randomized** to reduce temporal and thermal bias.

## Test Parameters

| Parameter | Value |
|-----------|-------|
| Warm-up duration | 30 seconds |
| Measurement duration | 60 seconds |
| Repetitions | 5 |
| Concurrency levels | 1, 10, 50, 100, 200 |

## Load Generators

| Protocol | Tool | Notes |
|----------|------|-------|
| REST | wrk2 / oha | High-precision latency |
| REST | k6 | Complementary, scenario scripting |
| gRPC | ghz | Native gRPC benchmarking |
| GraphQL | k6 | Fixed GraphQL documents |

All load generators run **inside the cluster** as Kubernetes Jobs, scheduled on a different node than the server.

## Metrics Collected

### Performance Metrics

- Requests/operations per second
- Latency: p50, p90, p95, p99, p99.9, max
- Error rate
- Timeouts

### Resource Metrics

- CPU mean and max (cores)
- CPU throttled seconds
- RSS mean and max (bytes)
- Working set
- Network received/transmitted (bytes)
- Pod restarts
- OOM kills

### Infrastructure Metrics

- Threads count
- Process count
- Worker count
- Image size (MB)
- Build time
- Cold start time
- Time to ready
- First request latency

### Environment Metrics

- Timestamp (UTC)
- CPU frequency
- Load average
- Concurrent workloads
- Server node name
- Load generator node name
- Image version (git SHA)
- K3s version
- Kernel version

## Output Format

Each run produces a JSON file (see `docs/RESULTS_SCHEMA.md`).

## Statistical Analysis

- **Primary metric**: Median of 5 repetitions
- **Secondary metrics**: Mean, standard deviation, min, max
- **Confidence**: 95% confidence interval when applicable
- **Outliers**: Not excluded automatically; documented if present

## What We Do NOT Do

- Use only the best execution
- Compare REST JSON throughput directly with gRPC Protobuf throughput
- Compare partial GraphQL responses with full REST responses
- Mix results from different replica counts
- Mix measured and estimated results
- Compare JVM warm runs with cold-start native runs

---

**Last Updated**: 2026-07-28
