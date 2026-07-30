# COMPLETE BENCHMARK RESULTS — ALL 43 Implementations × ALL Scenarios

**Date**: 2026-07-30
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**Test**: 50 connections, 2 threads, 5s measurement
**Classification**: MEASURED

---

## REST — ALL 23 Implementations × 5 Scenarios (req/s)

| # | Implementation | Health | JSON | DB-Simple | DB-Complex | Cache |
|---|---------------|--------|------|-----------|------------|-------|
| 1 | **csharp-rest-minimal-api** | **23.827** | **2.065** | 4.159 | 4.041 | 5.012 |
| 2 | **csharp-rest-controllers** | **19.815** | **2.119** | 2.704 | 2.282 | 3.136 |
| 3 | **go-rest-fiber** | 7.196 | 338 | **13.452** | **13.142** | 7.399 |
| 4 | kotlin-rest-ktor | 5.568 | 921 | 3.861 | 2.112 | **14.014** |
| 5 | deno-rest-deno-serve | 4.659 | 836 | 2.553 | 1.819 | 13.699 |
| 6 | deno-rest-hono | 4.484 | 829 | 2.622 | 1.729 | 13.452 |
| 7 | bun-rest-elysia | 4.090 | 1.851 | 2.255 | 45 | 8.684 |
| 8 | deno-rest-fresh | 3.850 | 772 | 2.507 | 1.735 | 12.668 |
| 9 | bun-rest-bun-serve | 3.755 | 1.072 | 2.851 | 2.405 | 7.162 |
| 10 | bun-rest-hono | 3.553 | 1.078 | 2.842 | 2.329 | 8.112 |
| 11 | nodejs-rest-fastify | 2.627 | 1.481 | 2.181 | 41 | 4.899 |
| 12 | nodejs-rest-nestjs | 2.323 | 2.422 | 1.978 | 2.320 | 2.205 |
| 13 | rust-rest-axum | 1.648 | 426 | 2.647 | 1.544 | 1.011 |
| 14 | rust-rest-actix-web | 1.572 | 328 | 1.681 | 2.924 | 1.062 |
| 15 | nodejs-rest-express | 1.580 | 535 | 1.291 | 37 | 2.187 |
| 16 | rust-rest-rocket | 1.441 | 291 | 2.163 | 1.566 | 1.321 |
| 17 | go-rest-gin | 1.294 | 254 | 678 | 350 | 5.124 |
| 18 | deno-rest-oak | 1.282 | 394 | 1.213 | 1.330 | 3.177 |
| 19 | go-rest-echo | 1.249 | 273 | 792 | 299 | 4.734 |
| 20 | graalvm-rest-vertx | 1.214 | 848 | 1.213 | 1.213 | 1.216 |
| 21 | python-rest-flask | 1.115 | 42 | 1.858 | 1.534 | 1.779 |
| 22 | python-rest-fastapi | 757 | 104 | 658 | 642 | 797 |
| 23 | python-rest-django | 401 | 368 | 384 | 395 | 394 |

---

## gRPC — ALL 17 Implementations (req/s)

| # | Implementation | Req/s | Status |
|---|---------------|-------|--------|
| 1 | **python-grpc-grpcio** | **4.295** | ✅ |
| 2 | **nodejs-grpc-connectrpc** | **4.126** | ✅ |
| 3 | **go-grpc-grpc-go** | **4.050** | ✅ |
| 4 | nodejs-grpc-grpc-js | 3.974 | ✅ |
| 5 | csharp-grpc-protobuf-net-grpc | 2.500 | ✅ |
| 6 | csharp-grpc-magiconion | 2.405 | ✅ |
| 7 | java-grpc-grpc-java | 2.085 | ✅ |
| 8 | bun-grpc-connectrpc | 1.743 | ✅ |
| 9 | python-grpc-betterproto | 1.771 | ✅ |
| 10 | bun-grpc-grpc-js | 1.065 | ✅ |
| 11 | bun-grpc-nice-grpc | 1.052 | ✅ |
| 12 | nodejs-grpc-nice-grpc | 1.068 | ✅ |
| 13 | nodejs-grpc-grpc-js | 3.974 | ✅ |
| 14 | python-grpc-grpclib | 590 | ✅ |
| 15 | deno-grpc-connectrpc | 2 | ❌ Redis ECONNREFUSED |
| 16 | deno-grpc-grpc-js | 2 | ❌ Redis ECONNREFUSED |
| 17 | deno-grpc-nice-grpc | 2 | ❌ Redis ECONNREFUSED |
| 18 | csharp-grpc-grpc-dotnet | 2 | ❌ Stack trace errors |

---

## GraphQL — ALL 7 Implementations (req/s)

| # | Implementation | Req/s | Status |
|---|---------------|-------|--------|
| 1 | **python-graphql-ariadne** | **3.589** | ✅ |
| 2 | **java-graphql-spring-graphql** | **1.380** | ✅ |
| 3 | **java-graphql-dgs** | **1.244** | ✅ |
| 4 | nodejs-graphql-yoga | 1.058 | ✅ |
| 5 | nodejs-graphql-apollo | 825 | ✅ |
| 6 | go-graphql-gqlgen | — | ❌ No pods |
| 7 | nodejs-graphql-mercurius | — | ❌ No pods |
| 8 | python-graphql-strawberry | — | ❌ No pods |

---

## Category Winners

| Category | Winner | Value |
|----------|--------|-------|
| **REST Health** | csharp-rest-minimal-api | 23.827 req/s |
| **REST JSON** | nodejs-rest-nestjs | 2.422 req/s |
| **REST DB Simple** | go-rest-fiber | 13.452 req/s |
| **REST DB Complex** | go-rest-fiber | 13.142 req/s |
| **REST Cache** | kotlin-rest-ktor | 14.014 req/s |
| **gRPC** | python-grpc-grpcio | 4.295 rps |
| **GraphQL** | python-graphql-ariadne | 3.589 req/s |

---

## Performance per Category (Top 3)

### REST Health (framework overhead)
1. C# Minimal API — 23.827
2. C# Controllers — 19.815
3. Go Fiber — 7.196

### REST JSON (serialization)
1. Node.js NestJS — 2.422
2. C# Controllers — 2.119
3. C# Minimal API — 2.065

### REST Database Simple
1. Go Fiber — 13.452
2. Kotlin Ktor — 3.861
3. C# Minimal API — 4.159

### REST Database Complex
1. Go Fiber — 13.142
2. Rust Actix Web — 2.924
3. C# Minimal API — 4.041

### REST Cache
1. Kotlin Ktor — 14.014
2. Deno Deno.serve — 13.699
3. Deno Hono — 13.452

### gRPC
1. Python grpcio — 4.295
2. Node.js ConnectRPC — 4.126
3. Go grpc-go — 4.050

### GraphQL
1. Python Ariadne — 3.589
2. Java Spring GraphQL — 1.380
3. Java DGS — 1.244

---

## Infrastructure

| Metric | Value |
|--------|-------|
| Server | K3s v1.34.6+k3s1 |
| CPU | 48 cores |
| RAM | 64 GB |
| Deployments | 42 |
| Pods Running | 43 |
| Total Tests | 134 |
| REST Tests | 115 (23 × 5) |
| gRPC Tests | 17 |
| GraphQL Tests | 7 |

---

**Last Updated**: 2026-07-30
