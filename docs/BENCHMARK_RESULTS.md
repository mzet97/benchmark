# Benchmark Results — Real Measurements

**Date**: 2026-07-29
**Server**: K3s v1.34.6+k3s1 (k8s1, 48 cores, 64GB RAM)
**Classification**: MEASURED

## Test Conditions

- Single node K3s cluster
- ~37 pods running simultaneously
- REST: 50 connections, 2 threads, 5s measurement
- gRPC: 5 connections, 10 concurrency, 5s measurement
- GraphQL: 50 connections, 2 threads, 5s measurement (POST /graphql)
- Endpoint: `/health` (REST), `Health` RPC (gRPC), `{ health { status timestamp } }` (GraphQL)

---

## REST Ranking (22 implementations)

| Rank | Implementation | Req/s | Latency Avg |
|------|---------------|-------|-------------|
| 🥇 | **rust-rest-actix-web** | **38.073** | 4.42ms |
| 🥈 | **csharp-rest-minimal-api** | **30.045** | 6.09ms |
| 🥉 | **csharp-rest-controllers** | **27.794** | 4.07ms |
| 4 | rust-rest-rocket | 26.691 | 2.86ms |
| 5 | rust-rest-axum | 24.409 | 2.14ms |
| 6 | deno-rest-deno-serve | 20.541 | 2.45ms |
| 7 | deno-rest-hono | 20.493 | 2.44ms |
| 8 | deno-rest-fresh | 19.618 | 2.55ms |
| 9 | bun-rest-bun-serve | 15.086 | 3.37ms |
| 10 | kotlin-rest-ktor | 14.160 | 7.10ms |
| 11 | go-rest-fiber | 14.155 | 13.61ms |
| 12 | bun-rest-hono | 13.364 | 3.75ms |
| 13 | bun-rest-elysia | 11.264 | 4.43ms |
| 14 | go-rest-echo | 10.514 | 12.04ms |
| 15 | go-rest-gin | 10.391 | 19.60ms |
| 16 | graalvm-rest-vertx | 4.751 | 13.57ms |
| 17 | nodejs-rest-fastify | 4.353 | 12.17ms |
| 18 | deno-rest-oak | 3.242 | 15.38ms |
| 19 | nodejs-rest-nestjs | 2.421 | 21.11ms |
| 20 | nodejs-rest-express | 2.178 | 24.59ms |
| 21 | python-rest-fastapi | 1.161 | 43.19ms |
| 22 | python-rest-django | 390 | 134.79ms |

### REST Category Winners

| Category | Winner | Value |
|----------|--------|-------|
| 🚀 Highest Throughput | rust-rest-actix-web | 38.073 req/s |
| ⚡ Lowest Latency | rust-rest-axum | 2.14ms |
| 🏆 Best Overall | rust-rest-actix-web | 38k req/s + 4.42ms |

### REST by Language

| Language | Best Framework | Req/s |
|----------|---------------|-------|
| Rust | actix-web | 38.073 |
| C# | minimal-api | 30.045 |
| Deno | deno-serve | 20.541 |
| Bun | bun-serve | 15.086 |
| Kotlin | ktor | 14.160 |
| Go | fiber | 14.155 |
| GraalVM | vertx | 4.751 |
| Node.js | fastify | 4.353 |
| Python | fastapi | 1.161 |

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

- MagicOnion (C#, MessagePack serialization) leads gRPC
- Many gRPC implementations had build/deploy issues
- gRPC benchmarks used proto file (no reflection)

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

- Java leads GraphQL (Spring GraphQL, DGS)
- Python Ariadne surprisingly competitive
- Query tested: `{ health { status timestamp } }`

---

## Cross-Protocol Summary

| Protocol | Top Implementation | Req/s | Latency |
|----------|-------------------|-------|---------|
| REST | rust-rest-actix-web | 38.073 | 4.42ms |
| gRPC | csharp-grpc-magiconion | 2.501 | 2.99ms |
| GraphQL | java-graphql-spring-graphql | 4.678 | 26.59ms |

**Note**: REST, gRPC, and GraphQL results are NOT directly comparable (different serialization, protocols, and connection handling).

---

## Deployment Status

| Protocol | Deployed | Running | Benchmarked |
|----------|----------|---------|-------------|
| REST | 27 | 22 | 22 |
| gRPC | 14 | 8 | 6 |
| GraphQL | 6 | 5 | 5 |
| **Total** | **47** | **35** | **33** |

---

## Resource Usage (during benchmark)

- CPU: ~788m (1% of 48 cores)
- Memory: ~8.4GB (13% of 64GB)
- Pods: 37 running

---

## Next Steps

1. Fix 6 remaining gRPC pods (nice-grpc, connectrpc, betterproto, grpclib)
2. Run benchmarks on all 5 scenarios (health, json, db-simple, db-complex, cache)
3. Run with higher concurrency (100, 200, 500)
4. Collect CPU/memory metrics per pod
5. Generate normalized rankings

---

**Last Updated**: 2026-07-29
