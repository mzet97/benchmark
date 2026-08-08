# E4 Validation Status — FINAL

**Atualizado**: 2026-08-08

## Resultado: 27/37 PASS 7/7 (73%)

| Status | Qtd |
|---|---|
| ✅ **E4 PASS (7/7)** | **27** |
| ⚠️ Parcial | 3 |
| ❌ TIMEOUT | 7 |

### ✅ E4 PASS (7/7) — 27 implementações, 10 ambientes

| # | Impl | Ambiente |
|---|---|---|
| 1 | `bun-rest-bun-serve` | Bun |
| 2 | `bun-rest-elysia` | Bun |
| 3 | `bun-rest-hono` | Bun |
| 4 | `go-rest-chi` | Go |
| 5 | `go-rest-echo` | Go |
| 6 | `go-rest-fiber` | Go |
| 7 | `go-rest-gin` | Go |
| 8 | `graalvm-rest-helidon` | GraalVM |
| 9 | `graalvm-rest-gspring` | GraalVM |
| 10 | `java-rest-spring` | Java |
| 11 | `java-rest-quarkus` | Java |
| 12 | `kotlin-rest-http4k` | Kotlin |
| 13 | `kotlin-rest-ktor` | Kotlin |
| 14 | `kotlin-rest-spring` | Kotlin |
| 15 | `nodejs-rest-express` | Node.js |
| 16 | `nodejs-rest-fastify` | Node.js |
| 17 | `nodejs-rest-nestjs` | Node.js |
| 18 | `python-rest-flask` | Python |
| 19 | `python-rest-fastapi` | Python |
| 20 | `python-rest-django` | Python |
| 21 | `dart-rest-vaden` | Dart |
| 22 | `rust-rest-actix-web` | Rust |
| 23 | `rust-rest-axum` | Rust |
| 24 | `rust-rest-rocket` | Rust |
| 25 | `rust-rest-warp` | Rust |
| 26 | `csharp-rest-controllers` | C# |
| 27 | `csharp-rest-fastendpoints` | C# |

**10 dos 11 ambientes representados** (só falta Deno).

### ⚠️ Parciais — 3 implementações (Micronaut DataSource injection)

| Impl | ok/7 | Falha |
|---|---|---|
| `graalvm-rest-gmicronaut` | 5/2 | /db/* — micronaut-data-processor |
| `graalvm-rest-micronaut` | 4/3 | /health, /db/* — DataSource @Named |
| `java-rest-micronaut` | 4/3 | /health, /db/* — DataSource @Named |

### ❌ TIMEOUT — 7 implementações

| Impl | Causa |
|---|---|
| `deno-rest-{oak,deno-serve,fresh,hono}` | Deno Redis auth (4) |
| `csharp-rest-minimalapi` | .NET listening on wrong port / payload |
| `graalvm-rest-spring` | Native image build fails |
| `graalvm-rest-vertx` | JAVA_TOOL_OPTIONS heap OOM |

## Progressão da sessão

| Rodada | PASS |
|---|---|
| Início | 0 |
| Após porta fix | 5 |
| Após DB config | 6 |
| Após payload batch 1 | 13 |
| Após stale rebuild | 15 |
| Após payload batch 2 | 18 |
| Após payload batch 3 | 25 |
| **Após Rust touch + NaiveDateTime** | **27** |
