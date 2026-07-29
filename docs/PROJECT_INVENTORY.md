# Project Inventory — Benchmark API REST/gRPC/GraphQL

## Legend

| Estado | Significado |
|--------|-------------|
| COMPLETE | Build OK, imagem OK, deploy OK, smoke test OK, benchmark real |
| PARTIAL | Código presente, mas sem benchmark real confirmado |
| PLACEHOLDER | Código existe mas é scaffold/template, não funcional |
| BROKEN | Não compila ou não funciona |
| DUPLICATE | Mesma implementação listada duas vezes |
| UNVERIFIED | Código existe mas não foi testado |
| EXPERIMENTAL | Implementação com dependências instáveis |

## REST Implementations

| ID | Ambiente | Protocolo | Framework | Diretório | Build | Imagem | Deploy | Smoke test | Benchmark real | Estado |
|----|----------|-----------|-----------|-----------|-------|--------|--------|------------|----------------|--------|
| 1 | Rust | REST | Actix Web | `src/rust/actix-web/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 2 | Rust | REST | Axum | `src/rust/axum/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 3 | Rust | REST | Rocket | `src/rust/rocket/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 4 | Rust | REST | Warp (aux) | `src/rust/warp/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 5 | Go | REST | Fiber | `src/go/fiber/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 6 | Go | REST | Gin | `src/go/gin/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 7 | Go | REST | Echo | `src/go/echo/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 8 | Go | REST | Chi (aux) | `src/go/chi/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 9 | C# | REST | MinimalApi | `src/csharp/MinimalApi/` | ✅ | ✅ | ✅ | UNVERIFIED | ⚠️ EXEMPLO | PARTIAL |
| 10 | C# | REST | Controllers | — | ❌ | ❌ | ❌ | ❌ | ❌ | MISSING |
| 11 | C# | REST | FastEndpoints | — | ❌ | ❌ | ❌ | ❌ | ❌ | MISSING |
| 12 | Node.js | REST | Fastify | `src/nodejs/fastify/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 13 | Node.js | REST | Express | `src/nodejs/express/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 14 | Node.js | REST | NestJS | `src/nodejs/nestjs/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 15 | Bun | REST | Bun.serve | `src/bun/bun_serve/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 16 | Bun | REST | Elysia | `src/bun/elysia/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 17 | Bun | REST | Hono | `src/bun/hono/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 18 | Kotlin | REST | Ktor | `src/kotlin/ktor/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 19 | Kotlin | REST | Spring Boot | `src/kotlin/spring/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 20 | Kotlin | REST | http4k | `src/kotlin/http4k/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 21 | Deno | REST | Deno.serve | `src/deno/deno_serve/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 22 | Deno | REST | Hono | `src/deno/hono/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 23 | Deno | REST | Oak | `src/deno/oak/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 24 | Deno | REST | Fresh (aux) | `src/deno/fresh/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PLACEHOLDER |
| 25 | Python | REST | FastAPI | `src/python/fastapi/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 26 | Python | REST | Flask | `src/python/flask/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 27 | Python | REST | Django | `src/python/django/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 28 | Dart | REST | Vaden (Shelf) | `src/dart/vaden/` | ✅* | ✅* | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL* |
| 29 | Java | REST | Quarkus | `src/java/quarkus/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 30 | Java | REST | Spring Boot | `src/java/spring/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 31 | Java | REST | Micronaut | `src/java/micronaut/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 32 | GraalVM | REST | Quarkus Native | `src/graalvm/gmicronaut/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 33 | GraalVM | REST | Micronaut Native | `src/graalvm/micronaut/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 34 | GraalVM | REST | Spring Native | `src/graalvm/gspring/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 35 | GraalVM | REST | Vert.x (aux) | `src/graalvm/vertx/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |
| 36 | GraalVM | REST | Helidon (aux) | `src/graalvm/helidon/` | ✅ | ✅ | ✅ | UNVERIFIED | ❌ ESTIMATED | PARTIAL |

### Notes on Dart (ID 28)

- **CORRECTED 2026-07-28**: The Dart implementation was BROKEN (pubspec.yaml had no runtime dependencies, bin/server.dart used raw dart:io without DB/Redis).
- Fixed to use Shelf (foundation of Vaden) with real PostgreSQL and Redis connections.
- Framework documented as "Vaden (Shelf)" since Vaden is built on Shelf.
- See `src/dart/vaden/` for the corrected implementation.

## gRPC Implementations

| ID | Ambiente | Protocolo | Framework | Diretório | Estado |
|----|----------|-----------|-----------|-----------|--------|
| — | All | gRPC | — | — | ❌ NONE |

**No gRPC implementations exist yet.** See `contracts/grpc/benchmark.proto` for the planned contract.

## GraphQL Implementations

| ID | Ambiente | Protocolo | Framework | Diretório | Estado |
|----|----------|-----------|-----------|-----------|--------|
| — | All | GraphQL | — | — | ❌ NONE |

**No GraphQL implementations exist yet.** See `contracts/graphql/schema.graphql` for the planned schema.

## Missing REST Implementations

| Ambiente | Framework | Status |
|----------|-----------|--------|
| C# | ASP.NET Core Controllers | MISSING — needs implementation |
| C# | FastEndpoints | MISSING — needs implementation |

## Infrastructure Status

| Component | Status | Notes |
|-----------|--------|-------|
| `kubernetes/secrets.yaml` | ⚠️ EXPOSED | Contains plaintext credentials |
| `kubernetes/secrets.example.yaml` | ✅ CREATED | Safe example file |
| `config/implementations.yaml` | ❌ MISSING | Needs creation |
| `contracts/grpc/benchmark.proto` | ❌ MISSING | Needs creation |
| `contracts/graphql/schema.graphql` | ❌ MISSING | Needs creation |
| `deploy/k3s/` (Kustomize) | ❌ MISSING | Needs creation |
| `deploy/k3s/loadgen/` | ❌ MISSING | Needs creation |
| `deploy/k3s/preflight/` | ❌ MISSING | Needs creation |
| `scripts/build-image.sh` | ❌ MISSING | Needs creation |
| `scripts/deploy.sh` (generic) | ❌ MISSING | Needs creation |
| `scripts/smoke-test.sh` | ❌ MISSING | Needs creation |
| `scripts/run-benchmark.sh` | ❌ MISSING | Needs creation |
| `results/raw/` | ❌ EMPTY | No raw data collected |

## Results Classification

| Category | Count | Description |
|----------|-------|-------------|
| MEASURED | 0 | No real benchmark data collected |
| ESTIMATED | ~35 | All existing "results" are projections |
| EXAMPLE | 1 | C# /health wrk output format |
| UNVERIFIED | 0 | — |

---

**Last Updated**: 2026-07-28
**Total Implementations**: 36 REST (34 PARTIAL, 1 PLACEHOLDER, 1 CORRECTED), 0 gRPC, 0 GraphQL
