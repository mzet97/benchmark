# E4 Validation Status — FINAL

**Atualizado**: 2026-08-08

## Resultado: 25/37 PASS 7/7 (68%)

| Status | Qtd |
|---|---|
| ✅ **E4 PASS (7/7)** | **25** |
| ⚠️ Parcial | 3 |
| ❌ TIMEOUT / build fail | 9 |

### ✅ E4 PASS (7/7) — 25 implementações, 10 ambientes

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
| 23 | `rust-rest-warp` | Rust |
| 24 | `csharp-rest-controllers` | C# |
| 25 | `csharp-rest-fastendpoints` | C# |

**10 dos 11 ambientes representados** (só falta Deno, que tem 4 TIMEOUTs).

### ⚠️ Parciais — 3 implementações

| Impl | ok/7 | Falha |
|---|---|---|
| `graalvm-rest-gmicronaut` | 5/2 | micronaut-data-processor (build fail) |
| `graalvm-rest-micronaut` | 4/3 | DataSource @Named injection |
| `java-rest-micronaut` | 4/3 | DataSource @Named injection |

### ❌ TIMEOUT — 9 implementações

| Impl | Causa |
|---|---|
| `deno-rest-{oak,deno-serve,fresh,hono}` | Deno bootstrap/image (4) |
| `csharp-rest-minimalapi` | .NET AOT startup |
| `graalvm-rest-spring` | Native image build falha |
| `graalvm-rest-vertx` | Runtime crash |
| `rust-rest-axum` | sqlx crash sem logs |
| `rust-rest-rocket` | sqlx crash sem logs |

## Progressão da sessão

| Rodada | PASS | Parcial | TIMEOUT |
|---|---|---|---|
| Início | 0 | 2 | 35 |
| Após porta fix | 5 | 15 | 17 |
| Após DB config | 6 | 20 | 11 |
| Após payload batch 1 | 13 | 15 | 9 |
| Após stale rebuild | 15 | 13 | 9 |
| Após payload batch 2 | 18 | 10 | 9 |
| Após payload batch 3 | 18 | 13 | 6 |
| **Após payload batch 4** | **25** | **3** | **9** |

## Próximos passos

1. **Iniciar matriz de benchmark** com as 25 impls que passam E4
2. Investigar os 3 Micronaut parciais (DataSource @Named)
3. Investigar os 9 TIMEOUTs (Deno, Rust, GraalVM, C#)
