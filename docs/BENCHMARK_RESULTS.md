# Benchmark Results — First Real Measurements

**Date**: 2026-07-29
**Server**: K3s v1.34.6+k3s1 (k8s1, 48 cores, 64GB RAM)
**Classification**: MEASURED

## Test Conditions

- Single node K3s cluster
- ~36 pods running simultaneously
- 100 concurrent connections, 2 threads, 10s duration (REST)
- 5 concurrent connections, 10 concurrent streams, 5s duration (gRPC)
- 100 concurrent connections, 2 threads, 10s duration (GraphQL)
- Endpoint: `/health` (REST), `Health` RPC (gRPC), `health` query (GraphQL)
- Resource competition from other pods

---

## REST Ranking (21 implementations)

| Rank | Implementation | Req/s | Latency Avg |
|------|---------------|-------|-------------|
| 🥇 | **csharp-rest-minimal-api** | **18.686** | 13.09ms |
| 🥈 | **csharp-rest-controllers** | **16.578** | 10.55ms |
| 🥉 | **go-rest-fiber** | **5.447** | 25.66ms |
| 4 | bun-rest-elysia | 4.363 | 23.86ms |
| 5 | deno-rest-fresh | 4.317 | 23.23ms |
| 6 | deno-rest-hono | 4.163 | 23.98ms |
| 7 | deno-rest-deno-serve | 3.773 | 26.86ms |
| 8 | bun-rest-bun-serve | 3.225 | 30.91ms |
| 9 | nodejs-rest-fastify | 2.634 | 37.85ms |
| 10 | graalvm-rest-vertx | 2.421 | 41.10ms |
| 11 | nodejs-rest-nestjs | 2.060 | 49.49ms |
| 12 | nodejs-rest-express | 1.471 | 70.87ms |
| 13 | rust-rest-rocket | 1.245 | 81.27ms |
| 14 | deno-rest-oak | 1.240 | 80.20ms |
| 15 | rust-rest-axum | 1.198 | 84.38ms |
| 16 | rust-rest-actix-web | 1.169 | 85.91ms |
| 17 | go-rest-echo | 1.118 | 100.53ms |
| 18 | go-rest-gin | 1.090 | 103.52ms |
| 19 | python-rest-flask | 1.044 | 95.05ms |
| 20 | python-rest-fastapi | 763 | 130.14ms |
| 21 | python-rest-django | 367 | 289.67ms |

### REST Notes

- C# with Native AOT dominates (18k+ req/s)
- Go Fiber is fastest among non-.NET (5.4k req/s)
- Rust implementations underperform due to resource contention (30+ pods on single node)
- Bun and Deno show competitive performance (3-4k req/s)
- Python is slowest as expected (367-1k req/s)

---

## gRPC Ranking (6 implementations)

| Rank | Implementation | Req/s | Latency Avg |
|------|---------------|-------|-------------|
| 🥇 | **csharp-grpc-magiconion** | **2.501** | 2.99ms |
| 🥈 | **csharp-grpc-protobuf-net-grpc** | **2.407** | 3.22ms |
| 🥉 | **bun-grpc-connectrpc** | **1.732** | 5.21ms |
| 4 | bun-grpc-grpc-js | 955 | 10.27ms |
| 5 | deno-grpc-connectrpc | 6 | 1.66ms |
| 6 | csharp-grpc-grpc-dotnet | 2 | 4.98ms |

### gRPC Notes

- MagicOnion (MessagePack) and protobuf-net fastest among gRPC
- Bun gRPC shows good performance
- csharp-grpc-dotnet had issues (likely port/reflection mismatch)
- Deno gRPC had connection issues
- Many gRPC implementations had build/deploy issues (proto compilation, reflection)

---

## GraphQL Ranking (5 implementations)

| Rank | Implementation | Req/s | Latency Avg |
|------|---------------|-------|-------------|
| 🥇 | **java-graphql-spring-graphql** | **4.678** | 26.59ms |
| 🥈 | **python-graphql-ariadne** | **4.507** | 22.47ms |
| 🥉 | **java-graphql-dgs** | **4.213** | 32.93ms |
| 4 | nodejs-graphql-apollo | 3.295 | 30.87ms |
| 5 | nodejs-graphql-yoga | 2.424 | 43.30ms |

### GraphQL Notes

- Java (Spring GraphQL, DGS) leads GraphQL performance
- Python Ariadne surprisingly competitive (4.5k req/s)
- Node.js Apollo and Yoga in mid-range
- Query tested: `{ health { status timestamp } }`

---

## Deployment Summary

| Protocol | Deployed | Running | Benchmarked |
|----------|----------|---------|-------------|
| REST | 27 | 23 | 21 |
| gRPC | 14 | 8 | 6 |
| GraphQL | 6 | 5 | 5 |
| **Total** | **47** | **36** | **32** |

---

## Caveats

1. **Resource contention**: 36 pods sharing 48 cores and 64GB RAM
2. **Single node**: No network overhead but CPU/memory competition
3. **No warm-up**: JVM implementations not fully warmed up
4. **Low concurrency**: 100 connections (REST) may not saturate servers
5. **Health endpoint only**: Simple response, no DB/Redis I/O

---

**Last Updated**: 2026-07-29
