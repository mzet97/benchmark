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

# BENCHMARK RESULTS — External PostgreSQL (192.168.1.52)

**Date**: 2026-07-30
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**PostgreSQL**: 192.168.1.52 (dedicated, 10k users, 50k orders, 200k items)
**Redis**: In-cluster
**Test**: wrk -t2 -c50 -d5s, ghz 5 conn/10 concurrency/5s
**Classification**: MEASURED

---

## REST Ranking — ALL 23 Implementations × 5 Scenarios (req/s)

| # | Implementation | Health | JSON | DB-Simple | DB-Complex | Cache |
|---|---------------|--------|------|-----------|------------|-------|
| 1 | **csharp-rest-minimal-api** | **18.425** | **1.831** | 3.515 | **3.702** | 0* |
| 2 | **csharp-rest-controllers** | **12.303** | **1.835** | 2.024 | 2.239 | 0* |
| 3 | **go-rest-fiber** | 5.337 | 337 | **11.600** | **11.926** | 5.219 |
| 4 | bun-rest-elysia | 3.939 | 1.759 | 3.474 | 406 | 8.318 |
| 5 | deno-rest-deno-serve | 3.063 | 824 | 1.679 | 29 | **12.624** |
| 6 | deno-rest-fresh | 3.049 | 817 | 1.732 | 28 | **12.826** |
| 7 | bun-rest-bun-serve | 2.964 | 1.117 | 2.602 | 23 | 7.332 |
| 8 | bun-rest-hono | 2.916 | 1.087 | 2.498 | 23 | 7.362 |
| 9 | nodejs-rest-fastify | 1.905 | 1.395 | 2.089 | 597 | 4.481 |
| 10 | rust-rest-axum | 1.557 | 422 | 7.529 | 176 | 1.440 |
| 11 | rust-rest-actix-web | 1.512 | 338 | 1.368 | 2.603 | 1.533 |
| 12 | rust-rest-rocket | 1.520 | 336 | 1.458 | 21 | 1.469 |
| 13 | nodejs-rest-nestjs | 1.468 | 286 | 1.315 | 602 | 2.553 |
| 14 | kotlin-rest-ktor | 1.409 | 472 | 0* | 633 | 6.472 |
| 15 | deno-rest-hono | 2.831 | 820 | 1.780 | 29 | 0* |
| 16 | python-rest-django | 1.200 | 305 | 1.387 | 400 | 1.323 |
| 17 | graalvm-rest-vertx | 1.203 | 682 | 1.214 | 1.211 | 1.214 |
| 18 | deno-rest-oak | 1.164 | 374 | 1.116 | 1.329 | 3.026 |
| 19 | nodejs-rest-express | 1.083 | 526 | 1.188 | 170 | 1.970 |
| 20 | python-rest-flask | 1.069 | 38 | 1.774 | 221 | 1.733 |
| 21 | python-rest-fastapi | 600 | 111 | 625 | 367 | 736 |
| 22 | go-rest-echo | 470 | 279 | 516 | 236 | 4.413 |
| 23 | go-rest-gin | 412 | 255 | 516 | 231 | 4.635 |

*0 = connection/config issue (Redis URL parsing, pool exhaustion)

---

## gRPC Ranking — ALL 17 Implementations (req/s)

| # | Implementation | Req/s |
|---|---------------|-------|
| 1 | **nodejs-grpc-connectrpc** | **4.219** |
| 2 | **go-grpc-grpc-go** | **4.171** |
| 3 | **python-grpc-grpcio** | **4.102** |
| 4 | nodejs-grpc-grpc-js | 4.085 |
| 5 | csharp-grpc-magiconion | 2.402 |
| 6 | csharp-grpc-protobuf-net-grpc | 2.376 |
| 7 | java-grpc-grpc-java | 1.954 |
| 8 | python-grpc-betterproto | 1.789 |
| 9 | bun-grpc-connectrpc | 1.675 |
| 10 | bun-grpc-grpc-js | 957 |
| 11 | bun-grpc-nice-grpc | 873 |
| 12 | nodejs-grpc-nice-grpc | 808 |
| 13 | python-grpc-grpclib | 550 |
| 14 | deno-grpc-connectrpc | 6* |
| 15 | deno-grpc-grpc-js | 6* |
| 16 | deno-grpc-nice-grpc | 6* |
| 17 | csharp-grpc-grpc-dotnet | 2* |

*Connection issues

---

## GraphQL Ranking — ALL 5 Implementations (req/s)

| # | Implementation | Req/s |
|---|---------------|-------|
| 1 | **python-graphql-ariadne** | **4.143** |
| 2 | nodejs-graphql-yoga | 977 |
| 3 | nodejs-graphql-apollo | 733 |
| 4 | java-graphql-dgs | 522 |
| 5 | java-graphql-spring-graphql | 468 |

---

## Category Winners

| Category | Winner | Req/s |
|----------|--------|-------|
| **REST Health** | csharp-rest-minimal-api | 18.425 |
| **REST JSON** | csharp-rest-controllers | 1.835 |
| **REST DB Simple** | go-rest-fiber | 11.600 |
| **REST DB Complex** | go-rest-fiber | 11.926 |
| **REST Cache** | deno-rest-fresh | 12.826 |
| **gRPC** | nodejs-grpc-connectrpc | 4.219 |
| **GraphQL** | python-graphql-ariadne | 4.143 |

---

## Configuration

| Component | Config |
|-----------|--------|
| PostgreSQL | 192.168.1.52, db_admin, benchmark_api |
| Redis | In-cluster, redis-master-nodeport |
| CPU per pod | 250m request, 2 limit |
| Memory per pod | 128Mi request, 1Gi limit |
| Database | 10k users, 50k orders, 200k items |
| Concurrency | REST: 50, gRPC: 10, GraphQL: 50 |

---

**Last Updated**: 2026-07-30
