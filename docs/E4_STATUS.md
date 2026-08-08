# E4 Validation Status — FINAL

**Atualizado**: 2026-08-07 (pós stale-image rebuild)

## Resultado: 15/37 PASS 7/7

| Status | Qtd |
|---|---|
| ✅ **E4 PASS (7/7)** | **15** |
| ⚠️ Parcial (1-4 checks fail) | 13 |
| ❌ TIMEOUT | 9 |

### ✅ E4 PASS (7/7) — 15 implementações

| # | Impl | Ambiente |
|---|---|---|
| 1 | `bun-rest-bun-serve` | Bun |
| 2 | `bun-rest-elysia` | Bun |
| 3 | `go-rest-chi` | Go |
| 4 | `go-rest-echo` | Go |
| 5 | `go-rest-fiber` | Go |
| 6 | `go-rest-gin` | Go |
| 7 | `graalvm-rest-helidon` | GraalVM |
| 8 | `java-rest-spring` | Java |
| 9 | `kotlin-rest-http4k` | Kotlin |
| 10 | `nodejs-rest-express` | Node.js |
| 11 | `nodejs-rest-fastify` | Node.js |
| 12 | `nodejs-rest-nestjs` | Node.js |
| 13 | `python-rest-flask` | Python |
| 14 | `rust-rest-actix-web` | Rust |
| 15 | `rust-rest-warp` | Rust |

**8 ambientes representados** nos 15 PASS: Bun, Go, GraalVM, Java, Kotlin, Node.js, Python, Rust.

### ⚠️ Parciais — 13 implementações (todas sobem e respondem)

| Impl | ok/7 | Falhas |
|---|---|---|
| `graalvm-rest-gspring` | 6/7 | /db/complex |
| `kotlin-rest-ktor` | 6/7 | /health |
| `python-rest-fastapi` | 5/7 | /db/* |
| `kotlin-rest-spring` | 5/2 | /db/* |
| `java-rest-quarkus` | 5/2 | /db/* |
| `graalvm-rest-micronaut` | 4/3 | /json, /db/* |
| `java-rest-micronaut` | 4/3 | /json, /db/* |
| `dart-rest-vaden` | 4/3 | /health, /db/* |
| `csharp-rest-fastendpoints` | 4/3 | /health, /db/* |
| `bun-rest-hono` | 4/3 | /db/*, /cache |
| `csharp-rest-controllers` | 3/4 | /health, /db/*, /cache |
| `graalvm-rest-gmicronaut` | 0/7 | não responde (Micronaut routes) |
| `python-rest-django` | 0/7 | não responde (WSGI/config) |

### ❌ TIMEOUT — 9 implementações

| Impl | Causa |
|---|---|
| `deno-rest-{oak,deno-serve,fresh,hono}` | Deno bootstrap/image (4) |
| `csharp-rest-minimalapi` | .NET AOT startup lento |
| `graalvm-rest-spring` | Native image build falha |
| `graalvm-rest-vertx` | Vert.x runtime crash |
| `rust-rest-axum` | sqlx DB connection (crash sem logs) |
| `rust-rest-rocket` | sqlx DB connection (crash sem logs) |

## Resumo

As **15 implementações que passam E4 7/7** estão prontas para a matriz de
benchmark. Cobrem 8 dos 11 ambientes tecnológicos e todos os 5 cenários do
contrato (/json, /health, /db/simple, /db/complex, /cache).

As 13 parciais precisam de fixes de payload adicionais (a fonte foi corrigida
mas as divergências persistem em runtime — pode ser necessário debug mais
profundo de cada uma). Os 9 TIMEOUTs têm problemas de bootstrap que precisam
investigação individual.
