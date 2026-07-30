# Complete Benchmark Results — All Protocols

**Date**: 2026-07-29
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**Classification**: MEASURED

---

## REST Ranking (22 implementations)

| Rank | Implementation | Req/s | Latency |
|------|---------------|-------|---------|
| 🥇 | rust-rest-actix-web | 38.073 | 4.42ms |
| 🥈 | csharp-rest-minimal-api | 30.045 | 6.09ms |
| 🥉 | csharp-rest-controllers | 27.794 | 4.07ms |
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

---

## gRPC Ranking (10 implementations)

| Rank | Implementation | Req/s |
|------|---------------|-------|
| 🥇 | nodejs-grpc-connectrpc | 4.140 |
| 🥈 | csharp-grpc-magiconion | 2.615 |
| 🥉 | csharp-grpc-protobuf-net-grpc | 2.486 |
| 4 | python-grpc-betterproto | 1.894 |
| 5 | bun-grpc-connectrpc | 1.797 |
| 6 | java-grpc-grpc-java | 1.539 |
| 7 | bun-grpc-grpc-js | 1.098 |
| 8 | bun-grpc-nice-grpc | 1.042 |
| 9 | nodejs-grpc-nice-grpc | 949 |
| 10 | python-grpc-grpclib | 612 |

---

## GraphQL Ranking (5 implementations)

| Rank | Implementation | Req/s | Latency |
|------|---------------|-------|---------|
| 🥇 | python-graphql-ariadne | 4.282 | 11.77ms |
| 🥈 | nodejs-graphql-yoga | 1.121 | 45.11ms |
| 🥉 | nodejs-graphql-apollo | 882 | 57.03ms |
| 4 | java-graphql-spring-graphql | 772 | 67.39ms |
| 5 | java-graphql-dgs | 627 | 81.74ms |

---

## Multi-Scenario REST (10 impls × 5 scenarios)

| Implementation | Health | JSON | DB-Simple | DB-Complex | Cache |
|---------------|--------|------|-----------|------------|-------|
| csharp-rest-minimal-api | 26.847 | 2.110 | 4.103 | 4.577 | 5.562 |
| csharp-rest-controllers | 21.391 | 2.075 | 2.513 | 2.461 | 3.439 |
| go-rest-fiber | 5.530 | 362 | 12.372 | 13.533 | 6.102 |
| deno-rest-deno-serve | 4.152 | 855 | 2.625 | 1.723 | 13.749 |
| bun-rest-bun-serve | 3.800 | 1.113 | 2.958 | 2.450 | 9.050 |
| kotlin-rest-ktor | 3.593 | 796 | 3.857 | 2.188 | 15.223 |
| bun-rest-hono | 3.126 | 1.105 | 2.876 | 2.436 | 7.091 |
| rust-rest-actix-web | 1.630 | 344 | 1.740 | 3.305 | 686 |
| rust-rest-rocket | 1.898 | 306 | 2.629 | 1.727 | 763 |
| rust-rest-axum | 1.753 | 422 | 2.586 | 1.574 | 672 |

---

## Category Winners

| Category | Winner | Value |
|----------|--------|-------|
| REST Health | csharp-rest-minimal-api | 26.847 req/s |
| REST JSON | csharp-rest-minimal-api | 2.110 req/s |
| REST DB Simple | go-rest-fiber | 12.372 req/s |
| REST DB Complex | go-rest-fiber | 13.533 req/s |
| REST Cache | kotlin-rest-ktor | 15.223 req/s |
| gRPC | nodejs-grpc-connectrpc | 4.140 rps |
| GraphQL | python-graphql-ariadne | 4.282 req/s |

---

## Deployment Summary

| Metric | Value |
|--------|-------|
| Total implementations coded | 101 |
| Deployments created | 42 |
| Pods running | 43 |
| Pods not ready | 0 |
| Implementations benchmarked | 37 |
| Scenarios tested | 5 |

---

**Last Updated**: 2026-07-29
