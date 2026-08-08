# E4 Validation Status — FINAL

**Atualizado**: 2026-08-07 (pós todos os fixes de runtime — batch final)

## Resultado: 13/37 PASS 7/7

| Status | Qtd |
|---|---|
| ✅ **E4 PASS (7/7)** | **13** |
| ⚠️ Parcial (1-4 checks fail) | 15 |
| ❌ TIMEOUT | 9 |

### ✅ E4 PASS (7/7) — 13 implementações

| # | Impl | Ambiente |
|---|---|---|
| 1 | `bun-rest-elysia` | Bun |
| 2 | `go-rest-chi` | Go |
| 3 | `go-rest-echo` | Go |
| 4 | `go-rest-fiber` | Go |
| 5 | `go-rest-gin` | Go |
| 6 | `graalvm-rest-helidon` | GraalVM |
| 7 | `kotlin-rest-http4k` | Kotlin |
| 8 | `nodejs-rest-express` | Node.js |
| 9 | `nodejs-rest-fastify` | Node.js |
| 10 | `nodejs-rest-nestjs` | Node.js |
| 11 | `python-rest-flask` | Python |
| 12 | `rust-rest-actix-web` | Rust |
| 13 | `rust-rest-warp` | Rust |

Todas passam o parity gate completo: `/json` (n=10/100/1000), `/health`,
`/db/simple`, `/db/complex`, `/cache`.

### ⚠️ Parciais — 15 implementações

| Impl | ok/7 | Falhas |
|---|---|---|
| `graalvm-rest-gspring` | 6/7 | /db/complex |
| `java-rest-spring` | 6/7 | /db/complex |
| `kotlin-rest-ktor` | 6/7 | /health (stale image?) |
| `python-rest-fastapi` | 5/7 | /db/* |
| `kotlin-rest-spring` | 5/2 | /db/* |
| `java-rest-quarkus` | 5/2 | /db/* |
| `bun-rest-bun-serve` | 5/2 | /db/*, /cache |
| `graalvm-rest-micronaut` | 4/3 | /json, /health, /db/* |
| `java-rest-micronaut` | 4/3 | /json, /health, /db/* |
| `dart-rest-vaden` | 4/3 | /health, /db/* |
| `csharp-rest-fastendpoints` | 4/3 | /health, /db/* |
| `bun-rest-hono` | 4/3 | /db/*, /cache |
| `csharp-rest-controllers` | 3/4 | /health, /db/*, /cache |
| `graalvm-rest-gmicronaut` | 0/7 | não responde |
| `python-rest-django` | 0/7 | não responde |

### ❌ TIMEOUT — 9 implementações

| Impl | Causa provável |
|---|---|
| `deno-rest-deno-serve` | Deno bootstrap/image |
| `deno-rest-fresh` | idem |
| `deno-rest-hono` | idem |
| `deno-rest-oak` | idem |
| `csharp-rest-minimalapi` | .NET AOT startup |
| `graalvm-rest-spring` | Native image build falha |
| `graalvm-rest-vertx` | Vert.x API issues |
| `rust-rest-axum` | sqlx DB connection |
| `rust-rest-rocket` | sqlx DB connection |

## Próximos passos

1. **Iniciar matriz de benchmark** com as 13 impls que passam E4 — já é um
   ranking defensável de 13 implementações em 7 ambientes
2. Fixar os 15 parciais (cada um precisa de 1-3 fixes de payload)
3. Investigar os 9 TIMEOUTs
