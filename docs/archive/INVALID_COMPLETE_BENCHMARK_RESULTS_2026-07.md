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

# COMPLETE BENCHMARK RESULTS — All 42 Implementations

**Date**: 2026-07-29
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**Test**: 50 connections, 2 threads, 5s measurement, /health endpoint
**Classification**: MEASURED

---

## REST Ranking (23 implementations)

| Rank | Implementation | Req/s | Latency |
|------|---------------|-------|---------|
| 🥇 | **csharp-rest-minimal-api** | **24.950** | 6.86ms |
| 🥈 | **csharp-rest-controllers** | **20.829** | 6.06ms |
| 🥉 | **go-rest-fiber** | **7.455** | 20.47ms |
| 4 | kotlin-rest-ktor | 5.130 | 21.87ms |
| 5 | bun-rest-elysia | 4.811 | 11.18ms |
| 6 | deno-rest-fresh | 4.811 | 10.43ms |
| 7 | deno-rest-deno-serve | 4.710 | 10.59ms |
| 8 | deno-rest-hono | 4.378 | 11.45ms |
| 9 | bun-rest-bun-serve | 3.675 | 14.36ms |
| 10 | bun-rest-hono | 3.535 | 14.10ms |
| 11 | nodejs-rest-fastify | 2.632 | 18.97ms |
| 12 | nodejs-rest-nestjs | 2.268 | 22.19ms |
| 13 | rust-rest-rocket | 1.789 | 27.87ms |
| 14 | rust-rest-axum | 1.752 | 28.65ms |
| 15 | go-rest-gin | 1.318 | 37.61ms |
| 16 | go-rest-echo | 1.285 | 38.55ms |
| 17 | graalvm-rest-vertx | 1.215 | 40.91ms |
| 18 | python-rest-flask | 1.126 | 44.28ms |
| 19 | python-rest-fastapi | 750 | 68.07ms |
| 20 | python-rest-django | 391 | 129.60ms |
| 21 | rust-rest-actix-web | 0* | N/A |
| 22 | nodejs-rest-express | 0* | N/A |
| 23 | deno-rest-oak | 0* | N/A |

*0 = timeout or connection error during test

---

## gRPC Ranking (14 implementations)

| Rank | Implementation | Req/s |
|------|---------------|-------|
| 🥇 | **nodejs-grpc-connectrpc** | **4.094** |
| 🥈 | **csharp-grpc-protobuf-net-grpc** | **2.497** |
| 🥉 | **csharp-grpc-magiconion** | **2.470** |
| 4 | java-grpc-grpc-java | 2.127 |
| 5 | python-grpc-betterproto | 1.876 |
| 6 | bun-grpc-connectrpc | 1.826 |
| 7 | bun-grpc-nice-grpc | 1.099 |
| 8 | bun-grpc-grpc-js | 1.089 |
| 9 | nodejs-grpc-nice-grpc | 1.045 |
| 10 | python-grpc-grpclib | 144 |
| 11 | csharp-grpc-grpc-dotnet | 0* |
| 12 | deno-grpc-connectrpc | 0* |
| 13 | deno-grpc-grpc-js | 0* |
| 14 | deno-grpc-nice-grpc | 0* |

*0 = reflection not supported or connection error

---

## GraphQL Ranking (5 implementations)

| Rank | Implementation | Req/s | Latency |
|------|---------------|-------|---------|
| 🥇 | **python-graphql-ariadne** | **4.148** | 12.19ms |
| 🥈 | **nodejs-graphql-yoga** | **1.118** | 44.66ms |
| 🥉 | **java-graphql-spring-graphql** | **963** | 53.67ms |
| 4 | nodejs-graphql-apollo | 921 | 53.97ms |
| 5 | java-graphql-dgs | 835 | 62.43ms |

---

## Summary by Protocol

| Protocol | Tested | Best | Best Impl |
|----------|--------|------|-----------|
| REST | 23 | 24.950 req/s | csharp-rest-minimal-api |
| gRPC | 14 | 4.094 rps | nodejs-grpc-connectrpc |
| GraphQL | 5 | 4.148 req/s | python-graphql-ariadne |

---

## Category Winners

| Category | Winner | Value |
|----------|--------|-------|
| REST Overall | csharp-rest-minimal-api | 24.950 req/s |
| REST Low Latency | csharp-rest-controllers | 6.06ms |
| gRPC | nodejs-grpc-connectrpc | 4.094 rps |
| GraphQL | python-graphql-ariadne | 4.148 req/s |

---

## Infrastructure

| Metric | Value |
|--------|-------|
| Server | K3s v1.34.6+k3s1 |
| CPU | 48 cores |
| RAM | 64 GB |
| Deployments | 42 |
| Pods Running | 43 |
| Implementations Tested | 42 |

---

**Last Updated**: 2026-07-29
