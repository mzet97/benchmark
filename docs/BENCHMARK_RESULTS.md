# Benchmark Results

**Status**: AWAITING REAL MEASUREMENTS

## Classification

| Tag | Meaning |
|-----|---------|
| MEASURED | Real benchmark data from actual execution |
| ESTIMATED | Projected values (not from real execution) |
| EXAMPLE | Template/format illustration |

## Current Data

All existing data in this repository is classified as **ESTIMATED**.
No real benchmark has been executed yet.

## Results Structure

Once benchmarks are executed, results will be stored as:

```
results/
  raw/
    <run-id>/
      <implementation-id>/
        <scenario>/
          <mode>/
            <concurrency>/
              run-<n>.json
  normalized/
    <protocol>/
      <scenario>/
        <mode>/
          <concurrency>/
            rankings.json
  reports/
    summary.json
```

## Rankings (Placeholder)

### REST — Mode A (Pod Single)

| Rank | Implementation | Req/s | p50 | p99 | Status |
|------|---------------|-------|-----|-----|--------|
| — | — | — | — | — | AWAITING DATA |

### gRPC — Mode A (Pod Single)

| Rank | Implementation | Ops/s | p50 | p99 | Status |
|------|---------------|-------|-----|-----|--------|
| — | — | — | — | — | AWAITING DATA |

### GraphQL — Mode A (Pod Single)

| Rank | Implementation | Req/s | p50 | p99 | Status |
|------|---------------|-------|-----|-----|--------|
| — | — | — | — | — | AWAITING DATA |

## How to Run

```bash
# 1. Build
make build IMPL=rust-rest-actix-web

# 2. Deploy in single-pod mode
make deploy IMPL=rust-rest-actix-web MODE=single-pod

# 3. Smoke test
make smoke IMPL=rust-rest-actix-web

# 4. Benchmark (REST with wrk)
kubectl apply -f deploy/k3s/loadgen/job-wrk.yaml -n benchmark

# 5. Collect results
kubectl logs job/benchmark-wrk -n benchmark

# 6. Undeploy
make undeploy IMPL=rust-rest-actix-web
```

## Environment Requirements

See `docs/REPRODUCIBILITY.md` for full requirements.

---

**Last Updated**: 2026-07-29
**Status**: AWAITING REAL MEASUREMENTS
