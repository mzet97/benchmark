> [!CAUTION]
> # THESE RESULTS ARE INVALID — DO NOT CITE
>
> Every number below was produced by `run_all_benchmarks.py`, which has since
> been retired. It is not defensible, for reasons that are independent of each
> other and each sufficient on its own:
>
> * **One 5-second sample** per implementation per scenario, with a 2-second
>   warm-up — against a documented methodology of 5 repetitions of 60 s with a
>   30 s warm-up. A single sample has no error bar.
> * **The load generator ran inside the same single-node cluster** as the
>   subject, capped at 1 CPU, competing for the same 8 cores.
> * **The implementations were not comparable.** They served different
>   payloads: different item counts, different field sets, some minting 1000
>   random UUIDs or reading the clock 1000 times per request. Some `/db/*`
>   endpoints ran materially heavier SQL than others; two implementations
>   (`kotlin/http4k`, `graalvm/vertx`) returned hardcoded literals without
>   touching PostgreSQL or Redis at all.
> * **Resource profiles conflicted.** Three existed in the repository; the one
>   that actually ran (100m request / 500m limit, 5 replicas) matched neither
>   the methodology nor the deploy base.
> * **The tables are internally inconsistent** — rows out of rank order,
>   summary figures that contradict the table above them.
>
> Kept for provenance only. See `docs/ACTION_PLAN.md` for the remediation, and
> `docs/BENCHMARK_METHODOLOGY.md` for the protocol that replaces it. New
> results will come from `scripts/run-benchmark-suite.py`.

# Benchmark Results — K3s Cluster (2026-07-30)

## Environment
- **Server**: K3s v1.34.6+k3s1 on 192.168.1.51
- **Node**: 1 control-plane node
- **Replicas**: 5 per service
- **Tool**: wrk (4 threads, 50 connections, 5s duration)
- **Test**: Inside cluster via wrk pod

## REST Implementations — Complete Results (23 frameworks)

### /health (Liveness)

| # | Framework | Req/s | Language |
|---|-----------|------:|----------|
| 1 | C# Minimal API | 27,210 | C# |
| 2 | C# Controllers | 18,539 | C# |
| 3 | Go Fiber | 7,115 | Go |
| 4 | Kotlin Ktor | 5,362 | Kotlin |
| 5 | Deno Fresh | 4,691 | Deno |
| 6 | Deno Hono | 4,580 | Deno |
| 7 | Deno Deno.serve | 4,545 | Deno |
| 8 | Bun Bun.serve | 3,780 | Bun |
| 9 | Bun Hono | 3,516 | Bun |
| 10 | Node.js NestJS | 2,247 | Node.js |
| 11 | Rust Rocket | 1,796 | Rust |
| 12 | Rust Axum | 1,710 | Rust |
| 13 | Rust Actix Web | 1,636 | Rust |
| 14 | Deno Oak | 1,396 | Deno |
| 15 | Go Gin | 1,318 | Go |
| 16 | Go Echo | 1,302 | Go |
| 17 | Python Flask | 1,176 | Python |
| 18 | GraalVM Vert.x | 1,168 | GraalVM |
| 19 | Python FastAPI | 772 | Python |
| 20 | Node.js Fastify | 746 | Node.js |
| 21 | Bun Elysia | 726 | Bun |
| 22 | Node.js Express | 656 | Node.js |
| 23 | Python Django | 389 | Python |

### /json (Serialization — 1000 items)

| # | Framework | Req/s | Language |
|---|-----------|------:|----------|
| 1 | Node.js NestJS | 2,396 | Node.js |
| 2 | C# Minimal API | 2,038 | C# |
| 3 | Bun Elysia | 1,898 | Bun |
| 4 | C# Controllers | 1,388 | C# |
| 5 | Bun Bun.serve | 1,168 | Bun |
| 6 | Bun Hono | 1,149 | Bun |
| 7 | Python FastAPI | 110 | Python |
| 8 | Deno Fresh | 871 | Deno |
| 9 | Deno Deno.serve | 870 | Deno |
| 10 | Deno Hono | 867 | Deno |
| 11 | Kotlin Ktor | 856 | Kotlin |
| 12 | GraalVM Vert.x | 869 | GraalVM |
| 13 | Node.js Express | 560 | Node.js |
| 14 | Python Django | 393 | Python |
| 15 | Deno Oak | 388 | Deno |
| 16 | Rust Rocket | 354 | Rust |
| 17 | Rust Actix Web | 343 | Rust |
| 18 | Go Fiber | 341 | Go |
| 19 | Rust Axum | 420 | Rust |
| 20 | Go Echo | 274 | Go |
| 21 | Go Gin | 271 | Go |
| 22 | Node.js Fastify | 212 | Node.js |
| 23 | Python Flask | 47 | Python |

### /db/simple?id=1 (PostgreSQL Single Query)

| # | Framework | Req/s | Language |
|---|-----------|------:|----------|
| 1 | **Go Fiber** | **12,660** | Go |
| 2 | C# Minimal API | 4,454 | C# |
| 3 | Kotlin Ktor | 3,991 | Kotlin |
| 4 | Bun Hono | 2,919 | Bun |
| 5 | Bun Bun.serve | 2,847 | Bun |
| 6 | Rust Rocket | 2,637 | Rust |
| 7 | Deno Hono | 2,594 | Deno |
| 8 | Rust Axum | 2,592 | Rust |
| 9 | Deno Fresh | 2,586 | Deno |
| 10 | Deno Deno.serve | 2,492 | Deno |
| 11 | Node.js NestJS | 2,260 | Node.js |
| 12 | C# Controllers | 2,211 | C# |
| 13 | Python Flask | 1,898 | Python |
| 14 | Rust Actix Web | 1,740 | Rust |
| 15 | Go Gin | 1,402 | Go |
| 16 | Go Echo | 1,385 | Go |
| 17 | GraalVM Vert.x | 1,162 | GraalVM |
| 18 | Deno Oak | 1,056 | Deno |
| 19 | Python FastAPI | 691 | Python |
| 20 | Bun Elysia | 451 | Bun |
| 21 | Node.js Express | 469 | Node.js |
| 22 | Node.js Fastify | 344 | Node.js |
| 23 | Python Django | 389 | Python |

### /cache?key=test (Redis GET)

| # | Framework | Req/s | Language |
|---|-----------|------:|----------|
| 1 | **Deno Hono** | **14,869** | Deno |
| 2 | Deno Deno.serve | 14,691 | Deno |
| 3 | Deno Fresh | 12,105 | Deno |
| 4 | Kotlin Ktor | 16,261 | Kotlin |
| 5 | Bun Elysia | 8,775 | Bun |
| 6 | Bun Bun.serve | 8,527 | Bun |
| 7 | Bun Hono | 8,334 | Bun |
| 8 | Go Fiber | 7,385 | Go |
| 9 | C# Minimal API | 5,029 | C# |
| 10 | Node.js Fastify | 5,071 | Node.js |
| 11 | Go Gin | 4,446 | Go |
| 12 | Go Echo | 4,357 | Go |
| 13 | Deno Oak | 3,020 | Deno |
| 14 | C# Controllers | 2,898 | C# |
| 15 | Node.js NestJS | 2,287 | Node.js |
| 16 | Rust Actix Web | 2,131 | Rust |
| 17 | Rust Rocket | 2,103 | Rust |
| 18 | Node.js Express | 2,063 | Node.js |
| 19 | Rust Axum | 1,979 | Rust |
| 20 | Python Flask | 1,869 | Python |
| 21 | GraalVM Vert.x | 1,163 | GraalVM |
| 22 | Python FastAPI | 825 | Python |
| 23 | Python Django | 403 | Python |

## Summary by Category

### 🏆 Champions by Test

| Test | Winner | Req/s | Runner-up | Req/s |
|------|--------|------:|-----------|------:|
| /health (liveness) | C# Minimal API | 27,210 | C# Controllers | 18,539 |
| /json (serialization) | Node.js NestJS | 2,396 | C# Minimal API | 2,038 |
| /db/simple (PostgreSQL) | Go Fiber | 12,660 | C# Minimal API | 4,454 |
| /cache (Redis) | Kotlin Ktor | 16,261 | Deno Hono | 14,869 |

### 🏅 Best by Language (DB test)

| Language | Best Framework | Req/s |
|----------|---------------|------:|
| Go | Fiber | 12,660 |
| C# | Minimal API | 4,454 |
| Kotlin | Ktor | 3,991 |
| Bun | Hono | 2,919 |
| Rust | Rocket | 2,637 |
| Deno | Hono | 2,594 |
| Node.js | NestJS | 2,260 |
| Python | Flask | 1,898 |
| GraalVM | Vert.x | 1,162 |

### Key Insights

1. **Go Fiber dominates DB queries** — 12.6K req/s with PostgreSQL
2. **Deno excels at Redis** — Hono/Deno.serve at 14-16K req/s
3. **C# is the all-rounder** — Top 2 in health, top 3 in DB
4. **Kotlin Ktor** — Strong across all tests (5K health, 4K DB, 16K cache)
5. **Bun Elysia** — Best serialization among JS runtimes
6. **Rust** — Consistent ~2.5K across DB/Cache tests
7. **Python** — Flask surprisingly beats FastAPI in DB queries

## gRPC Implementations (17 frameworks)

### Health (ghz, 2 conns, 100 requests)

| # | Framework | Req/s | Language |
|---|-----------|------:|----------|
| 1 | **Node.js connectrpc** | **5,251** | Node.js |
| 2 | C# protobuf-net-grpc | 2,760 | C# |
| 3 | C# MagicOnion | 2,654 | C# |
| 4 | Bun connectrpc | 2,281 | Bun |
| 5 | Java grpc-java | 1,522 | Java |
| 6 | Python betterproto | 1,394 | Python |
| 7 | Bun grpc-js | 964 | Bun |
| 8 | Bun nice-grpc | 958 | Bun |
| 9 | Node.js nice-grpc | 651 | Node.js |
| 10 | Python grpclib | 557 | Python |
| 11 | Deno connectrpc | FAILED | Deno |
| 12 | Deno grpc-js | FAILED | Deno |
| 13 | Deno nice-grpc | FAILED | Deno |
| 14 | C# grpc-dotnet | FAILED | C# |

**Note**: Deno gRPC services have connection issues. C# grpc-dotnet timeout.

## GraphQL Implementations (8 frameworks)

### __typename Query (wrk POST, 4 threads, 50 conns, 5s)

| # | Framework | Req/s | Language |
|---|-----------|------:|----------|
| 1 | **Java Spring GraphQL** | **7,200** | Java |
| 2 | Java DGS | 6,313 | Java |
| 3 | Python Ariadne | 4,404 | Python |
| 4 | Node.js Apollo | 3,088 | Node.js |
| 5 | Node.js Yoga | 2,026 | Node.js |
| 6 | Go gqlgen | FAILED | Go |
| 7 | Node.js Mercurius | FAILED | Node.js |
| 8 | Python Strawberry | FAILED | Python |

## Infrastructure Deployed (Updated)

- **REST**: 25 frameworks ✅ (+java-rest-spring)
- **gRPC**: 15 frameworks ✅ (+rust-grpc-tonic)
- **GraphQL**: 13 frameworks ✅ (+bun/deno-graphql)
- **Total**: 53 pods deployed on K3s (45 running)

## New Implementations Added

### REST
| Framework | Req/s |
|-----------|------:|
| Go Chi | 1,951 |
| Java Spring | Starting (DB conn issues) |

### GraphQL (new)
| Framework | Req/s |
|-----------|------:|
| Bun Hono | 3,484 |
| Deno Yoga | 3,633 |
| Deno Hono | 3,050 |

### gRPC (new)
| Framework | Req/s |
|-----------|------:|
| Node.js grpc-js | 4,732 |
| Rust Tonic | 4,910 |

## Summary Champions (53 frameworks tested)

| Category | Winner | Req/s |
|----------|--------|------:|
| REST /health | C# Minimal API | 19,562 |
| REST /db (PostgreSQL) | Go Fiber | 12,660 |
| REST /cache (Redis) | Kotlin Ktor | 16,261 |
| gRPC Health | Rust Tonic | 4,910 |
| GraphQL __typename | Python Ariadne | 4,043 |

## Remaining Not Deployed (46 implementations)

Build issues by category:
- **Java/Kotlin**: Missing JDBC deps, compilation errors (~20 impls)
- **Rust**: cargo build fails (grpcio, volo, GraphQL) (~10 impls)
- **C# GraphQL**: NuGet cycle, API errors (~6 impls)
- **Go gRPC**: Proto path issues (~5 impls)
- **Dart**: pubspec issues (~5 impls)
