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

# High Concurrency Benchmark Results

**Date**: 2026-07-29
**Server**: K3s v1.34.6+k3s1 (48 cores, 64GB RAM)
**Classification**: MEASURED

---

## REST Health — 200 Connections (4 threads, 10s)

| Rank | Implementation | Req/s | Latency Avg | p99 |
|------|---------------|-------|-------------|-----|
| 🥇 | csharp-rest-minimal-api | 21.706 | 18.83ms | 76.83ms |
| 🥈 | csharp-rest-controllers | 21.251 | 12.35ms | 54.02ms |
| 🥉 | go-rest-fiber | 6.361 | 37.26ms | 94.61ms |
| 4 | kotlin-rest-ktor | 5.366 | 40.86ms | 95.98ms |
| 5 | deno-rest-deno-serve | 3.996 | 49.79ms | 61.43ms |
| 6 | bun-rest-bun-serve | 3.422 | 58.11ms | 69.54ms |
| 7 | bun-rest-hono | 3.184 | 62.38ms | 74.64ms |
| 8 | rust-rest-rocket | 1.261 | 154.38ms | 341.15ms |
| 9 | rust-rest-axum | 1.192 | 156.29ms | 344.95ms |
| 10 | rust-rest-actix-web | 1.176 | 167.08ms | 346.27ms |

---

## REST Health — 500 Connections (4 threads, 10s)

| Rank | Implementation | Req/s | Latency Avg | p99 |
|------|---------------|-------|-------------|-----|
| 🥇 | csharp-rest-minimal-api | 23.442 | 27.23ms | 85.68ms |
| 🥈 | go-rest-fiber | 6.091 | 81.51ms | 612.62ms |
| 🥉 | kotlin-rest-ktor | 5.068 | 97.98ms | 192.88ms |
| 4 | deno-rest-deno-serve | 3.865 | 127.91ms | 142.36ms |
| 5 | bun-rest-bun-serve | 3.445 | 143.41ms | 156.21ms |

---

## REST DB Simple — 200 Connections

| Rank | Implementation | Req/s |
|------|---------------|-------|
| 🥇 | go-rest-fiber | 12.578 |
| 🥈 | kotlin-rest-ktor | 3.977 |
| 🥉 | csharp-rest-minimal-api | 3.634 |

---

## Analysis

### C# Native AOT
- Consistently top-tier at all concurrency levels
- Scales well from 100 to 500 connections (21k → 23k)
- Lowest p99 latency at high concurrency

### Go Fiber
- Best DB performance (12.5k req/s with PostgreSQL)
- Health throughput stable around 6k
- p99 latency spikes at 500 connections (612ms)

### Rust
- Surprisingly low performance under high concurrency
- Likely connection handling bottleneck
- Needs investigation (connection pool, tokio runtime config)

### Deno/Bun
- Consistent mid-range performance
- Good p99 latency stability

### Kotlin Ktor
- Strong all-around performer
- Excellent DB performance

---

**Last Updated**: 2026-07-29
