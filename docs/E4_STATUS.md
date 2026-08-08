# E4 Validation Status — FINAL

**Atualizado**: 2026-08-08

## Resultado: 29/37 PASS 7/7 (78%)

| Status | Qtd |
|---|---|
| ✅ **E4 PASS (7/7)** | **29** |
| ⚠️ Parcial | 1 |
| ❌ TIMEOUT | 7 |

### ✅ E4 PASS (7/7) — 29 implementações, 10 ambientes

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
| 10 | `graalvm-rest-micronaut` | GraalVM |
| 11 | `java-rest-spring` | Java |
| 12 | `java-rest-quarkus` | Java |
| 13 | `java-rest-micronaut` | Java |
| 14 | `kotlin-rest-http4k` | Kotlin |
| 15 | `kotlin-rest-ktor` | Kotlin |
| 16 | `kotlin-rest-spring` | Kotlin |
| 17 | `nodejs-rest-express` | Node.js |
| 18 | `nodejs-rest-fastify` | Node.js |
| 19 | `nodejs-rest-nestjs` | Node.js |
| 20 | `python-rest-flask` | Python |
| 21 | `python-rest-fastapi` | Python |
| 22 | `python-rest-django` | Python |
| 23 | `dart-rest-vaden` | Dart |
| 24 | `rust-rest-actix-web` | Rust |
| 25 | `rust-rest-axum` | Rust |
| 26 | `rust-rest-rocket` | Rust |
| 27 | `rust-rest-warp` | Rust |
| 28 | `csharp-rest-controllers` | C# |
| 29 | `csharp-rest-fastendpoints` | C# |

**10 dos 11 ambientes representados** (só falta Deno, que tem 1 parcial).

### ⚠️ Parcial — 1 implementação

| Impl | ok/7 | Falha |
|---|---|---|
| `deno-rest-oak` | 6/7 | 1 check |

### ❌ TIMEOUT — 7 implementações

| Impl | Causa |
|---|---|
| `deno-rest-deno-serve` | `--unstable-net` flag needed |
| `deno-rest-fresh` | Redis workers crash (code 70) |
| `deno-rest-hono` | ImagePullBackOff (import pendente) |
| `csharp-rest-minimalapi` | ImagePullBackOff (import pendente) |
| `graalvm-rest-gmicronaut` | Build fail (micronaut-data) |
| `graalvm-rest-vertx` | Wrapper script may not work |
| `graalvm-rest-spring` | Native image build fails |

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
| Após Rust touch + NaiveDateTime | 27 |
| **Após Micronaut DatasourceFactory** | **29** |
