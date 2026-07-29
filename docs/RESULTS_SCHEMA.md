# Results Schema

## JSON Output Format

Every benchmark run produces a JSON file with the following structure:

```json
{
  "runId": "uuid-v4",
  "gitCommit": "abc1234",
  "implementationId": "rust-rest-actix-web",
  "environment": "rust",
  "protocol": "rest",
  "framework": "actix-web",
  "frameworkVersion": "4.x",
  "runtimeVersion": "1.x",
  "mode": "single-pod",
  "scenario": "health",
  "replicas": 1,
  "concurrency": 200,
  "warmupSeconds": 30,
  "durationSeconds": 60,
  "requests": 12345678,
  "requestsPerSecond": 205761,
  "errors": 0,
  "timeouts": 0,
  "latencyMs": {
    "mean": 0.97,
    "p50": 0.85,
    "p90": 1.23,
    "p95": 1.45,
    "p99": 2.34,
    "p999": 5.67,
    "max": 12.34
  },
  "resources": {
    "cpuMeanCores": 0.85,
    "cpuMaxCores": 0.98,
    "cpuThrottledSeconds": 0.0,
    "rssMeanBytes": 15728640,
    "rssMaxBytes": 20971520,
    "networkReceiveBytes": 1234567,
    "networkTransmitBytes": 2345678
  },
  "kubernetes": {
    "k3sVersion": "v1.28.x+k3s1",
    "nodeName": "node-1",
    "loadgenNodeName": "node-2",
    "podNames": ["rust-rest-actix-web-abc123"],
    "podRestarts": 0
  },
  "timestampUtc": "2026-07-28T12:00:00.000Z"
}
```

## Directory Structure

```
results/
  raw/
    <runId>/
      <implementationId>/
        <scenario>/
          <mode>/
            <concurrency>/
              run-<n>.json          # Individual run
  normalized/
    <protocol>/
      <scenario>/
        <mode>/
          <concurrency>/
            rankings.json           # Normalized rankings
  reports/
    summary.json                    # Overall summary
    rankings/
      rest-health-single-pod.json
      grpc-health-single-pod.json
      graphql-health-single-pod.json
      ...
  environment/
    <timestamp>/
      cluster-info.json
      node-info.json
      versions.json
```

## Classification Tags

| Tag | Meaning |
|-----|---------|
| `MEASURED` | Real benchmark data collected from actual execution |
| `ESTIMATED` | Projected values, not from real execution |
| `EXAMPLE` | Template or illustration, not real data |
| `UNVERIFIED` | Data exists but hasn't been validated |

## Ranking Rules

Rankings are produced **separately** for:

- REST vs gRPC vs GraphQL (never mixed)
- Mode A vs Mode B vs Mode C (never mixed)
- Per-scenario (health, json, db-simple, db-complex, cache-hit, cache-miss)

### What We Do NOT Rank

- A single combined ranking mixing REST, gRPC, and GraphQL by throughput
- JSON vs Protobuf without explaining serialization differences
- Partial GraphQL response vs full REST response
- 1 replica vs 5 replicas
- 1 worker vs N workers
- JVM warm run vs cold-start native

---

**Last Updated**: 2026-07-28
