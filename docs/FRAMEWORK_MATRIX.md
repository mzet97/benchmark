# Framework Matrix

**Last Updated**: 2026-07-29
**Total**: 101 implementations across 11 environments × 3 protocols

## REST — Primary Rankings (3 per environment)

| Environment | Framework 1 | Framework 2 | Framework 3 | Auxiliary |
|-------------|-------------|-------------|-------------|-----------|
| **Rust** | Actix Web | Axum | Rocket | Warp |
| **Go** | Fiber | Gin | Echo | Chi |
| **C#/.NET** | Minimal API | Controllers ✅ | FastEndpoints ✅ | — |
| **Node.js** | Fastify | Express | NestJS | — |
| **Bun** | Bun.serve | Elysia | Hono | — |
| **Kotlin/JVM** | Ktor | Spring Boot | http4k | — |
| **Deno** | Deno.serve | Hono | Oak | Fresh |
| **Python** | FastAPI | Flask | Django (DRF) | — |
| **Dart** | Vaden (Shelf) ✅ | — | — | — |
| **Java/JVM** | Quarkus | Spring Boot | Micronaut | — |
| **GraalVM Native** | Quarkus Native | Micronaut Native | Spring Native | Vert.x, Helidon |

## gRPC — Complete Matrix (33 implementations)

| Environment | Option 1 | Option 2 | Option 3 | Option 4 |
|-------------|----------|----------|----------|----------|
| **Rust** | tonic ✅ | Volo gRPC ✅ | grpcio ✅ | — |
| **Go** | grpc-go ✅ | ConnectRPC ✅ | Kitex ✅ | — |
| **C#/.NET** | gRPC for ASP.NET Core ✅ | protobuf-net.Grpc ✅ | MagicOnion ✅ | — |
| **Node.js** | @grpc/grpc-js ✅ | nice-grpc ✅ | ConnectRPC ✅ | — |
| **Bun** | @grpc/grpc-js ✅ | nice-grpc ✅ | ConnectRPC ✅ | — |
| **Deno** | @grpc/grpc-js ✅ | nice-grpc ✅ | ConnectRPC ✅ | — |
| **Python** | grpcio ✅ | grpclib ✅ | betterproto ✅ | — |
| **Dart** | grpc-dart ✅ | — | — | — |
| **Java/JVM** | grpc-java ✅ | Armeria gRPC ✅ | Quarkus gRPC ✅ | Spring gRPC ✅ |
| **Kotlin/JVM** | grpc-kotlin ✅ | Spring gRPC ✅ | Armeria gRPC ✅ | — |
| **GraalVM Native** | Quarkus gRPC Native ✅ | Micronaut gRPC Native ✅ | grpc-java Native ✅ | — |

### gRPC Notes
- **betterproto** (Python): Uses grpclib as its gRPC engine internally.
- **Bun/Deno gRPC**: All 3 options implemented. HTTP/2 compatibility needs validation.
- **Dart**: Only 1 mature server implementation (grpc-dart).
- **MagicOnion** (C#): Uses MessagePack serialization, not protobuf.

## GraphQL — Complete Matrix (32 implementations)

| Environment | Option 1 | Option 2 | Option 3 |
|-------------|----------|----------|----------|
| **Rust** | async-graphql + Axum ✅ | async-graphql + Actix ✅ | Juniper ✅ |
| **Go** | gqlgen ✅ | graph-gophers/graphql-go ✅ | graphql-go/graphql ✅ |
| **C#/.NET** | Hot Chocolate ✅ | GraphQL.NET ✅ | EntityGraphQL ✅ |
| **Node.js** | Apollo Server ✅ | Mercurius ✅ | GraphQL Yoga ✅ |
| **Bun** | GraphQL Yoga ✅ | Apollo Server ✅ | @hono/graphql-server ✅ |
| **Deno** | GraphQL Yoga ✅ | Apollo Server ✅ | @hono/graphql-server ✅ |
| **Python** | Strawberry ✅ | Ariadne ✅ | Graphene ✅ |
| **Dart** | graphql_server2 ✅ | Angel3 GraphQL ✅ | Leto ✅ |
| **Java/JVM** | Spring for GraphQL ✅ | Netflix DGS ✅ | — |
| **Kotlin/JVM** | GraphQL Kotlin ✅ | Spring for GraphQL ✅ | Netflix DGS ✅ |
| **GraalVM Native** | SmallRye GraphQL Native ✅ | Spring for GraphQL Native ✅ | Micronaut GraphQL Native ✅ |

### GraphQL Notes
- **Rust async-graphql**: Axum and Actix integrations share the same GraphQL engine (HTTP integration difference).
- **Java**: Missing SmallRye GraphQL (Quarkus) — only 2 implementations.
- All implementations use `POST /graphql`, disable playground/introspection.

## Implementation Count

| Protocol | Planned | Implemented | Missing |
|----------|---------|-------------|---------|
| REST | 36 | 36 | 0 |
| gRPC | 33 | 33 | 0 |
| GraphQL | 33 | 32 | 1 (Java SmallRye GraphQL) |
| **Total** | **102** | **101** | **1** |
