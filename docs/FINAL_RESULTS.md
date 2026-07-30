# COMPLETE BENCHMARK RESULTS — All 42 Implementations

**Date**: 2026-07-30
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**Classification**: MEASURED

---

## REST Ranking (23 implementations)

| Rank | Implementation | Req/s | Latency | CPU | Memory |
|------|---------------|-------|---------|-----|--------|
| 🥇 | **csharp-rest-minimal-api** | **24.950** | 6.86ms | 1m | 64Mi |
| 🥈 | **csharp-rest-controllers** | **20.829** | 6.06ms | 1m | 90Mi |
| 🥉 | **go-rest-fiber** | **7.455** | 20.47ms | 1m | 27Mi |
| 4 | kotlin-rest-ktor | 5.130 | 21.87ms | 2m | 205Mi |
| 5 | bun-rest-elysia | 4.811 | 11.18ms | 2m | 113Mi |
| 6 | deno-rest-fresh | 4.811 | 10.43ms | 1m | 62Mi |
| 7 | deno-rest-deno-serve | 4.710 | 10.59ms | 1m | 71Mi |
| 8 | deno-rest-hono | 4.378 | 11.45ms | 1m | 41Mi |
| 9 | bun-rest-bun-serve | 3.675 | 14.36ms | 1m | 68Mi |
| 10 | bun-rest-hono | 3.535 | 14.10ms | 2m | 62Mi |
| 11 | nodejs-rest-fastify | 2.632 | 18.97ms | 5m | 57Mi |
| 12 | nodejs-rest-nestjs | 2.268 | 22.19ms | 1m | 61Mi |
| 13 | rust-rest-rocket | 1.789 | 27.87ms | 1m | 46Mi |
| 14 | rust-rest-axum | 1.752 | 28.65ms | 769m | 27Mi |
| 15 | go-rest-gin | 1.318 | 37.61ms | 1m | 31Mi |
| 16 | go-rest-echo | 1.285 | 38.55ms | 1m | 24Mi |
| 17 | graalvm-rest-vertx | 1.215 | 40.91ms | 2m | 154Mi |
| 18 | python-rest-flask | 1.126 | 44.28ms | 2m | 149Mi |
| 19 | python-rest-fastapi | 750 | 68.07ms | 2m | 56Mi |
| 20 | python-rest-django | 391 | 129.60ms | 2m | 143Mi |

---

## gRPC Ranking (14 implementations)

| Rank | Implementation | Req/s | CPU | Memory |
|------|---------------|-------|-----|--------|
| 🥇 | **nodejs-grpc-connectrpc** | **4.094** | 1m | 35Mi |
| 🥈 | **csharp-grpc-protobuf-net-grpc** | **2.497** | 1m | 57Mi |
| 🥉 | **csharp-grpc-magiconion** | **2.470** | 1m | 60Mi |
| 4 | java-grpc-grpc-java | 2.127 | 2m | 137Mi |
| 5 | python-grpc-betterproto | 1.876 | 1m | 25Mi |
| 6 | bun-grpc-connectrpc | 1.826 | 2m | 46Mi |
| 7 | bun-grpc-nice-grpc | 1.099 | 2m | 45Mi |
| 8 | bun-grpc-grpc-js | 1.089 | 3m | 50Mi |
| 9 | nodejs-grpc-nice-grpc | 1.045 | 1m | 37Mi |
| 10 | python-grpc-grpclib | 144 | 1m | 26Mi |

---

## GraphQL Ranking (5 implementations)

| Rank | Implementation | Req/s | Latency | CPU | Memory |
|------|---------------|-------|---------|-----|--------|
| 🥇 | **python-graphql-ariadne** | **4.148** | 12.19ms | 2m | 33Mi |
| 🥈 | **nodejs-graphql-yoga** | **1.118** | 44.66ms | 1m | 78Mi |
| 🥉 | **java-graphql-spring-graphql** | **963** | 53.67ms | 2m | 270Mi |
| 4 | nodejs-graphql-apollo | 921 | 53.97ms | 1m | 41Mi |
| 5 | java-graphql-dgs | 835 | 62.43ms | 3m | 261Mi |

---

## Multi-Scenario Results (Top 10 REST)

| Implementation | Health | JSON | DB-Simple | DB-Complex | Cache |
|---------------|--------|------|-----------|------------|-------|
| csharp-rest-minimal-api | 24.950 | 2.094 | 4.594 | 4.463 | 5.566 |
| csharp-rest-controllers | 20.829 | 2.054 | 2.549 | 2.442 | 3.289 |
| go-rest-fiber | 7.455 | 0 | 13.215 | 13.374 | 6.953 |
| kotlin-rest-ktor | 5.130 | 825 | 3.682 | 2.260 | 15.240 |
| bun-rest-elysia | 4.811 | 1.948 | 2.251 | 0 | 9.104 |
| deno-rest-fresh | 4.811 | 836 | 2.789 | 1.619 | 14.161 |
| deno-rest-deno-serve | 4.710 | 0 | 2.491 | 1.643 | 14.324 |
| bun-rest-bun-serve | 3.675 | 1.118 | 2.991 | 2.622 | 8.954 |
| nodejs-rest-fastify | 2.632 | 1.269 | 2.238 | 43 | 5.144 |
| rust-rest-axum | 1.752 | 423 | 0 | 1.580 | 0 |

---

## Resource Usage (All 43 Pods)

| Metric | Value |
|--------|-------|
| Total CPU | 836m (0.8 cores) |
| Total Memory | 3.272 Mi (3.2 Gi) |
| Avg CPU per pod | 19m |
| Avg Memory per pod | 76 Mi |

### Lowest Memory

| Implementation | Memory |
|---------------|--------|
| go-rest-echo | 24Mi |
| rust-rest-actix-web | 24Mi |
| python-grpc-betterproto | 25Mi |
| python-grpc-grpclib | 26Mi |
| go-rest-fiber | 27Mi |

### Highest Memory

| Implementation | Memory |
|---------------|--------|
| java-graphql-spring-graphql | 270Mi |
| java-graphql-dgs | 261Mi |
| kotlin-rest-ktor | 205Mi |
| graalvm-rest-vertx | 154Mi |
| python-rest-flask | 149Mi |

---

## Category Winners

| Category | Winner | Value |
|----------|--------|-------|
| REST Health | csharp-rest-minimal-api | 24.950 req/s |
| REST JSON | csharp-rest-minimal-api | 2.094 req/s |
| REST DB Simple | go-rest-fiber | 13.215 req/s |
| REST DB Complex | go-rest-fiber | 13.374 req/s |
| REST Cache | kotlin-rest-ktor | 15.240 req/s |
| gRPC | nodejs-grpc-connectrpc | 4.094 rps |
| GraphQL | python-graphql-ariadne | 4.148 req/s |
| Lowest Memory | go-rest-echo | 24Mi |
| Best Perf/Mem | go-rest-fiber | 277 req/s per Mi |

---

## Infrastructure Summary

| Metric | Value |
|--------|-------|
| Total implementations coded | 101 |
| Deployments in K3s | 42 |
| Pods running | 43 |
| Implementations tested | 42 |
| Scenarios tested | 5 |
| Concurrency levels | 4 (50, 100, 200, 500) |
| Protocolos | 3 |

---

**Last Updated**: 2026-07-30
