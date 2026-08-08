# E4 Validation Status — FINAL

**Atualizado**: 2026-08-08

## Resultado: 18/37 PASS 7/7

| Status | Qtd |
|---|---|
| ✅ **E4 PASS (7/7)** | **18** |
| ⚠️ Parcial (1-2 checks fail) | 10 |
| ❌ TIMEOUT | 9 |

### ✅ E4 PASS (7/7) — 18 implementações, 9 ambientes

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
| 9 | `java-rest-spring` | Java |
| 10 | `kotlin-rest-http4k` | Kotlin |
| 11 | `kotlin-rest-ktor` | Kotlin |
| 12 | `nodejs-rest-express` | Node.js |
| 13 | `nodejs-rest-fastify` | Node.js |
| 14 | `nodejs-rest-nestjs` | Node.js |
| 15 | `python-rest-flask` | Python |
| 16 | `dart-rest-vaden` | Dart |
| 17 | `rust-rest-actix-web` | Rust |
| 18 | `rust-rest-warp` | Rust |

**9 dos 11 ambientes representados** (faltam apenas C# e Deno).

### ⚠️ Parciais — 10 implementações (todas sobem e respondem)

| Impl | ok/7 | Falha restante |
|---|---|---|
| `graalvm-rest-gspring` | 6/7 | /db/complex |
| `python-rest-fastapi` | 6/7 | 1 check |
| `java-rest-quarkus` | 6/7 | 1 check |
| `csharp-rest-fastendpoints` | 6/1 | 1 check |
| `csharp-rest-controllers` | 6/1 | 1 check |
| `python-rest-django` | 6/1 | 1 check |
| `graalvm-rest-gmicronaut` | 5/2 | 2 checks |
| `kotlin-rest-spring` | 5/2 | /db/* |
| `graalvm-rest-micronaut` | 4/3 | 3 checks |
| `java-rest-micronaut` | 4/3 | 3 checks |

### ❌ TIMEOUT — 9 implementações

Deno×4 (bootstrap), csharp-minimalapi (AOT startup), graalvm-spring (native build),
graalvm-vertx (runtime crash), rust-axum/rocket (sqlx crash sem logs).

## Progressão da sessão

| Rodada | PASS | Parcial | TIMEOUT |
|---|---|---|---|
| Início | 0 | 2 | 35 |
| Após porta fix | 5 | 15 | 17 |
| Após DB config | 6 | 20 | 11 |
| Após payload fixes | 13 | 15 | 9 |
| **Atual** | **18** | **10** | **9** |
