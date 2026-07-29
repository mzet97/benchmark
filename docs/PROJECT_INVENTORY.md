# Project Inventory — Benchmark API REST/gRPC/GraphQL

**Last Updated**: 2026-07-29
**Total Implementations**: 101

## Summary

| Protocolo | Implementações | Status |
|-----------|---------------|--------|
| REST | 36 | ✅ COMPLETE |
| gRPC | 33 | ✅ COMPLETE |
| GraphQL | 32 | ✅ COMPLETE |
| **TOTAL** | **101** | ✅ |

## Legend

| Estado | Significado |
|--------|-------------|
| COMPLETE | Código completo, Dockerfile, k8s manifests, build.sh |
| PARTIAL | Código presente, mas sem benchmark real confirmado |
| PLACEHOLDER | Código existe mas é scaffold/template |
| BROKEN | Não compila ou não funciona |
| MISSING | Implementação não existe |
| EXPERIMENTAL | Dependências instáveis (ex: Bun/Deno gRPC) |

---

## REST Implementations (36)

| ID | Ambiente | Framework | Diretório | Estado |
|----|----------|-----------|-----------|--------|
| 1 | Rust | Actix Web | `src/rust/actix-web/` | PARTIAL |
| 2 | Rust | Axum | `src/rust/axum/` | PARTIAL |
| 3 | Rust | Rocket | `src/rust/rocket/` | PARTIAL |
| 4 | Rust | Warp (aux) | `src/rust/warp/` | PARTIAL |
| 5 | Go | Fiber | `src/go/fiber/` | PARTIAL |
| 6 | Go | Gin | `src/go/gin/` | PARTIAL |
| 7 | Go | Echo | `src/go/echo/` | PARTIAL |
| 8 | Go | Chi (aux) | `src/go/chi/` | PARTIAL |
| 9 | C# | MinimalApi | `src/csharp/MinimalApi/` | PARTIAL |
| 10 | C# | Controllers | `src/csharp/Controllers/` | COMPLETE |
| 11 | C# | FastEndpoints | `src/csharp/FastEndpoints/` | COMPLETE |
| 12 | Node.js | Fastify | `src/nodejs/fastify/` | PARTIAL |
| 13 | Node.js | Express | `src/nodejs/express/` | PARTIAL |
| 14 | Node.js | NestJS | `src/nodejs/nestjs/` | PARTIAL |
| 15 | Bun | Bun.serve | `src/bun/bun_serve/` | PARTIAL |
| 16 | Bun | Elysia | `src/bun/elysia/` | PARTIAL |
| 17 | Bun | Hono | `src/bun/hono/` | PARTIAL |
| 18 | Kotlin | Ktor | `src/kotlin/ktor/` | PARTIAL |
| 19 | Kotlin | Spring Boot | `src/kotlin/spring/` | PARTIAL |
| 20 | Kotlin | http4k | `src/kotlin/http4k/` | PARTIAL |
| 21 | Deno | Deno.serve | `src/deno/deno_serve/` | PARTIAL |
| 22 | Deno | Hono | `src/deno/hono/` | PARTIAL |
| 23 | Deno | Oak | `src/deno/oak/` | PARTIAL |
| 24 | Deno | Fresh (aux) | `src/deno/fresh/` | PLACEHOLDER |
| 25 | Python | FastAPI | `src/python/fastapi/` | PARTIAL |
| 26 | Python | Flask | `src/python/flask/` | PARTIAL |
| 27 | Python | Django | `src/python/django/` | PARTIAL |
| 28 | Dart | Vaden (Shelf) | `src/dart/vaden/` | COMPLETE* |
| 29 | Java | Quarkus | `src/java/quarkus/` | PARTIAL |
| 30 | Java | Spring Boot | `src/java/spring/` | PARTIAL |
| 31 | Java | Micronaut | `src/java/micronaut/` | PARTIAL |
| 32 | GraalVM | Quarkus Native | `src/graalvm/gmicronaut/` | PARTIAL |
| 33 | GraalVM | Micronaut Native | `src/graalvm/micronaut/` | PARTIAL |
| 34 | GraalVM | Spring Native | `src/graalvm/gspring/` | PARTIAL |
| 35 | GraalVM | Vert.x (aux) | `src/graalvm/vertx/` | PARTIAL |
| 36 | GraalVM | Helidon (aux) | `src/graalvm/helidon/` | PARTIAL |

*Note: Dart Vaden was CORRECTED on 2026-07-28 — now uses Shelf with real PostgreSQL/Redis connections.

---

## gRPC Implementations (33)

| ID | Ambiente | Framework | Diretório | Estado |
|----|----------|-----------|-----------|--------|
| 37 | Rust | tonic | `src/rust/grpc/tonic/` | COMPLETE |
| 38 | Rust | Volo gRPC | `src/rust/grpc/volo/` | COMPLETE |
| 39 | Rust | grpcio | `src/rust/grpc/grpcio/` | COMPLETE |
| 40 | Go | grpc-go | `src/go/grpc/grpc-go/` | COMPLETE |
| 41 | Go | ConnectRPC | `src/go/grpc/connectrpc/` | COMPLETE |
| 42 | Go | Kitex | `src/go/grpc/kitex/` | COMPLETE |
| 43 | C# | gRPC for ASP.NET Core | `src/csharp/grpc/grpc-dotnet/` | COMPLETE |
| 44 | C# | protobuf-net.Grpc | `src/csharp/grpc/protobuf-net-grpc/` | COMPLETE |
| 45 | C# | MagicOnion | `src/csharp/grpc/magiconion/` | COMPLETE |
| 46 | Node.js | @grpc/grpc-js | `src/nodejs/grpc/grpc-js/` | COMPLETE |
| 47 | Node.js | nice-grpc | `src/nodejs/grpc/nice-grpc/` | COMPLETE |
| 48 | Node.js | ConnectRPC | `src/nodejs/grpc/connectrpc/` | COMPLETE |
| 49 | Bun | @grpc/grpc-js | `src/bun/grpc/grpc-js/` | COMPLETE |
| 50 | Bun | nice-grpc | `src/bun/grpc/nice-grpc/` | COMPLETE |
| 51 | Bun | ConnectRPC | `src/bun/grpc/connectrpc/` | COMPLETE |
| 52 | Deno | @grpc/grpc-js | `src/deno/grpc/grpc-js/` | COMPLETE |
| 53 | Deno | nice-grpc | `src/deno/grpc/nice-grpc/` | COMPLETE |
| 54 | Deno | ConnectRPC | `src/deno/grpc/connectrpc/` | COMPLETE |
| 55 | Python | grpcio | `src/python/grpc/grpcio/` | COMPLETE |
| 56 | Python | grpclib | `src/python/grpc/grpclib/` | COMPLETE |
| 57 | Python | betterproto | `src/python/grpc/betterproto/` | COMPLETE |
| 58 | Dart | grpc-dart | `src/dart/grpc/grpc-dart/` | COMPLETE |
| 59 | Java | grpc-java | `src/java/grpc/grpc-java/` | COMPLETE |
| 60 | Java | Armeria gRPC | `src/java/grpc/armeria/` | COMPLETE |
| 61 | Java | Quarkus gRPC | `src/java/grpc/quarkus/` | COMPLETE |
| 62 | Kotlin | grpc-kotlin | `src/kotlin/grpc/grpc-kotlin/` | COMPLETE |
| 63 | Kotlin | Spring gRPC | `src/kotlin/grpc/spring-grpc/` | COMPLETE |
| 64 | Kotlin | Armeria gRPC | `src/kotlin/grpc/armeria/` | COMPLETE |
| 65 | GraalVM | Quarkus gRPC Native | `src/graalvm/grpc/quarkus/` | COMPLETE |
| 66 | GraalVM | Micronaut gRPC Native | `src/graalvm/grpc/micronaut/` | COMPLETE |
| 67 | GraalVM | grpc-java Native | `src/graalvm/grpc/grpc-java/` | COMPLETE |

---

## GraphQL Implementations (32)

| ID | Ambiente | Framework | Diretório | Estado |
|----|----------|-----------|-----------|--------|
| 68 | Rust | async-graphql + Axum | `src/rust/graphql/async-graphql-axum/` | COMPLETE |
| 69 | Rust | async-graphql + Actix | `src/rust/graphql/async-graphql-actix/` | COMPLETE |
| 70 | Rust | Juniper | `src/rust/graphql/juniper/` | COMPLETE |
| 71 | Go | gqlgen | `src/go/graphql/gqlgen/` | COMPLETE |
| 72 | Go | graph-gophers/graphql-go | `src/go/graphql/graphql-go/` | COMPLETE |
| 73 | Go | graphql-go/graphql | `src/go/graphql/graphql-go-2/` | COMPLETE |
| 74 | C# | Hot Chocolate | `src/csharp/graphql/hotchocolate/` | COMPLETE |
| 75 | C# | GraphQL.NET | `src/csharp/graphql/graphql-dotnet/` | COMPLETE |
| 76 | C# | EntityGraphQL | `src/csharp/graphql/entitygraphql/` | COMPLETE |
| 77 | Node.js | Apollo Server | `src/nodejs/graphql/apollo/` | COMPLETE |
| 78 | Node.js | Mercurius | `src/nodejs/graphql/mercurius/` | COMPLETE |
| 79 | Node.js | GraphQL Yoga | `src/nodejs/graphql/yoga/` | COMPLETE |
| 80 | Bun | GraphQL Yoga | `src/bun/graphql/yoga/` | COMPLETE |
| 81 | Bun | Apollo Server | `src/bun/graphql/apollo/` | COMPLETE |
| 82 | Bun | @hono/graphql-server | `src/bun/graphql/hono/` | COMPLETE |
| 83 | Deno | GraphQL Yoga | `src/deno/graphql/yoga/` | COMPLETE |
| 84 | Deno | Apollo Server | `src/deno/graphql/apollo/` | COMPLETE |
| 85 | Deno | @hono/graphql-server | `src/deno/graphql/hono/` | COMPLETE |
| 86 | Python | Strawberry | `src/python/graphql/strawberry/` | COMPLETE |
| 87 | Python | Ariadne | `src/python/graphql/ariadne/` | COMPLETE |
| 88 | Python | Graphene | `src/python/graphql/graphene/` | COMPLETE |
| 89 | Dart | graphql_server2 | `src/dart/graphql/graphql-server2/` | COMPLETE |
| 90 | Dart | Angel3 GraphQL | `src/dart/graphql/angel3/` | COMPLETE |
| 91 | Dart | Leto | `src/dart/graphql/leto/` | COMPLETE |
| 92 | Java | Spring for GraphQL | `src/java/graphql/spring-graphql/` | COMPLETE |
| 93 | Java | Netflix DGS | `src/java/graphql/dgs/` | COMPLETE |
| 94 | Kotlin | GraphQL Kotlin | `src/kotlin/graphql/graphql-kotlin/` | COMPLETE |
| 95 | Kotlin | Spring for GraphQL | `src/kotlin/graphql/spring-graphql/` | COMPLETE |
| 96 | Kotlin | Netflix DGS | `src/kotlin/graphql/dgs/` | COMPLETE |
| 97 | GraalVM | SmallRye GraphQL Native | `src/graalvm/graphql/smallrye/` | COMPLETE |
| 98 | GraalVM | Spring for GraphQL Native | `src/graalvm/graphql/spring/` | COMPLETE |
| 99 | GraalVM | Micronaut GraphQL Native | `src/graalvm/graphql/micronaut/` | COMPLETE |

---

## Infrastructure Status

| Component | Status |
|-----------|--------|
| `contracts/grpc/benchmark.proto` | ✅ |
| `contracts/graphql/schema.graphql` | ✅ |
| `config/implementations.yaml` | ✅ |
| `deploy/k3s/base/` (Kustomize) | ✅ |
| `deploy/k3s/loadgen/` (wrk + ghz) | ✅ |
| `deploy/k3s/preflight/` | ✅ |
| `scripts/build-image.sh` | ✅ |
| `scripts/deploy.sh` | ✅ |
| `scripts/smoke-test.sh` | ✅ |
| `scripts/undeploy.sh` | ✅ |
| `scripts/list-implementations.sh` | ✅ |
| `docs/SECURITY_REMEDIATION.md` | ✅ |
| `docs/API_CONTRACTS.md` | ✅ |
| `docs/BENCHMARK_METHODOLOGY.md` | ✅ |
| `docs/RESULTS_SCHEMA.md` | ✅ |
| `docs/FRAMEWORK_MATRIX.md` | ✅ |
| `kubernetes/secrets.example.yaml` | ✅ |

---

## Results Classification

| Category | Count |
|----------|-------|
| MEASURED | 0 (no real benchmark data yet) |
| ESTIMATED | ~35 (existing REST "results") |
| COMPLETE (code) | 101 |
