# Benchmark Results — K3s Cluster (2026-07-30)

## Environment
- **Server**: K3s v1.34.6+k3s1 on 192.168.1.51
- **Node**: 1 control-plane node
- **Replicas**: 5 per service
- **Tool**: wrk (8 threads, 200 connections, 10s duration)
- **Endpoint**: `/health` (HTTP GET)

## REST Implementations (23 frameworks)

| # | Framework | Req/s | Latency (avg) | Language |
|---|-----------|------:|---------------:|----------|
| 1 | C# Minimal API | 26,678 | 8.22ms | C# |
| 2 | C# Controllers | 21,288 | 14.81ms | C# |
| 3 | Go Fiber | 5,930 | 58.70ms | Go |
| 4 | Kotlin Ktor | 5,037 | 42.85ms | Kotlin |
| 5 | GraalVM Vert.x | 4,556 | 41.88ms | GraalVM |
| 6 | Bun Elysia | 4,275 | 47.28ms | Bun |
| 7 | Deno Fresh | 4,088 | 48.66ms | Deno |
| 8 | Deno Deno.serve | 3,832 | 51.93ms | Deno |
| 9 | Deno Hono | 3,708 | 53.62ms | Deno |
| 10 | Bun Bun.serve | 3,367 | 59.62ms | Bun |
| 11 | Bun Hono | 3,179 | 62.61ms | Bun |
| 12 | Node.js NestJS | 2,288 | 84.72ms | Node.js |
| 13 | Node.js Fastify | 2,096 | 129.04ms | Node.js |
| 14 | Rust Rocket | 1,569 | 116.45ms | Rust |
| 15 | Rust Axum | 1,534 | 116.58ms | Rust |
| 16 | Rust Actix Web | 1,495 | 133.21ms | Rust |
| 17 | Node.js Express | 1,425 | 157.52ms | Node.js |
| 18 | Go Echo | 1,424 | 141.43ms | Go |
| 19 | Go Gin | 1,400 | 139.97ms | Go |
| 20 | Deno Oak | 1,060 | 186.71ms | Deno |
| 21 | Python Flask | 1,102 | 179.57ms | Python |
| 22 | Python FastAPI | 749 | 278.32ms | Python |
| 23 | Python Django | 377 | 512.11ms | Python |

## Key Insights

### Top Performers by Language
- **C#**: .NET is the clear winner with 26K+ req/s
- **Go**: Fiber delivers ~6K req/s
- **Kotlin**: Ktor at 5K req/s
- **GraalVM**: Vert.x native at 4.5K req/s
- **Bun/Deno**: JavaScript runtimes at 3-4K req/s
- **Rust**: Surprisingly at ~1.5K (likely resource constrained)
- **Python**: Expected lower performance (377-1.1K req/s)

### Observations
1. **C# dominates** — Minimal API with .NET 8 is extremely fast
2. **Go Fiber** is the fastest Go framework
3. **Bun Elysia** beats all Deno frameworks
4. **Rust** performance is lower than expected — may need tuning
5. **Python Django** is the slowest as expected (full framework overhead)

### Health Endpoint Notes
- All 23 REST implementations respond to `/health`
- Services are exposed via ClusterIP on port 80
- Container ports vary: 8080 (Java/Kotlin/C#/Rust/Go), 3000 (Bun/Node.js), 8000 (Python/Deno)

## Next Steps
- [ ] Run `/api/json` benchmark (serialization test)
- [ ] Run `/api/users` benchmark (database test)
- [ ] Run `/api/cache` benchmark (Redis test)
- [ ] Deploy missing implementations (Dart, GraalVM REST variants)
- [ ] Run gRPC and GraphQL benchmarks
