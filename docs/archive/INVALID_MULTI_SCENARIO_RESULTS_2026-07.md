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

# Multi-Scenario Benchmark Results

**Date**: 2026-07-29
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**Test**: 100 connections, 2 threads, 5s measurement per scenario
**Classification**: MEASURED

## Results by Scenario (req/s)

| Implementation | Health | JSON | DB-Simple | DB-Complex | Cache |
|---------------|--------|------|-----------|------------|-------|
| csharp-rest-minimal-api | **26.847** | **2.110** | 4.103 | 4.577 | 5.562 |
| csharp-rest-controllers | **21.391** | **2.075** | 2.513 | 2.461 | 3.439 |
| go-rest-fiber | 5.530 | 362 | **12.372** | **13.533** | 6.102 |
| deno-rest-deno-serve | 4.152 | 855 | 2.625 | 1.723 | **13.749** |
| bun-rest-bun-serve | 3.800 | 1.113 | 2.958 | 2.450 | 9.050 |
| kotlin-rest-ktor | 3.593 | 796 | 3.857 | 2.188 | **15.223** |
| bun-rest-hono | 3.126 | 1.105 | 2.876 | 2.436 | 7.091 |
| rust-rest-actix-web | 1.630 | 344 | 1.740 | 3.305 | 686 |
| rust-rest-rocket | 1.898 | 306 | 2.629 | 1.727 | 763 |
| rust-rest-axum | 1.753 | 422 | 2.586 | 1.574 | 672 |

## Category Winners

| Scenario | Winner | Req/s | Notes |
|----------|--------|-------|-------|
| Health (pure framework) | csharp-rest-minimal-api | 26.847 | Native AOT |
| JSON serialization | csharp-rest-minimal-api | 2.110 | Native AOT |
| DB Simple (single row) | go-rest-fiber | 12.372 | pgx driver |
| DB Complex (JOIN+agg) | go-rest-fiber | 13.533 | pgx driver |
| Cache (Redis hit/miss) | kotlin-rest-ktor | 15.223 | Lettuce client |

## Analysis

### Health Endpoint
- C# Native AOT dominates (26k-21k req/s)
- Rust underperforms (1.6k-1.9k) — likely due to resource contention from 37 pods
- Go Fiber at 5.5k, Deno/Bun at 3-4k

### JSON Serialization (1000 objects)
- All implementations slower than health (serialization overhead)
- C# leads at 2.1k, Bun/Deno at 800-1.1k
- Rust very slow (300-422) — serialization bottleneck

### Database Simple Query
- Go Fiber dominates at 12.3k (pgx driver efficiency)
- Kotlin at 3.8k, C# at 4.1k
- Rust at 1.7-2.6k

### Database Complex Query
- Go Fiber again leads at 13.5k
- C# at 4.5k
- Rust at 1.5-3.3k

### Cache (Redis)
- Kotlin Ktor leads at 15.2k (Lettuce Redis client)
- Deno at 13.7k (native Redis)
- Bun at 9k
- Rust very slow (686-763) — Redis client issue

## Notes

1. **Rust performance anomaly**: Rust implementations show lower than expected performance. This is likely due to:
   - Resource contention (37 pods on single node)
   - Redis client overhead (redis-rs crate)
   - Not warmed up properly

2. **Go Fiber DB performance**: Exceptional database performance due to pgx driver efficiency and connection pooling.

3. **Kotlin Cache performance**: Lettuce Redis client shows excellent cache throughput.

4. **C# Native AOT**: Consistently top-tier across all scenarios.

---

**Last Updated**: 2026-07-29
