# Framework Matrix

## REST — Primary Rankings (3 per environment)

| Environment | Framework 1 | Framework 2 | Framework 3 | Auxiliary |
|-------------|-------------|-------------|-------------|-----------|
| **Rust** | Actix Web | Axum | Rocket | Warp |
| **Go** | Fiber | Gin | Echo | Chi |
| **C#/.NET** | Minimal API | Controllers | FastEndpoints | — |
| **Node.js** | Fastify | Express | NestJS | — |
| **Bun** | Bun.serve | Elysia | Hono | — |
| **Kotlin/JVM** | Ktor | Spring Boot | http4k | — |
| **Deno** | Deno.serve | Hono | Oak | Fresh |
| **Python** | FastAPI | Flask | Django (DRF) | — |
| **Dart** | Vaden (Shelf) | — | — | — |
| **Java/JVM** | Quarkus | Spring Boot | Micronaut | — |
| **GraalVM Native** | Quarkus Native | Micronaut Native | Spring Native | Vert.x, Helidon |

### Notes

- **C# Controllers** and **FastEndpoints** are MISSING — need implementation
- **Dart** has only 1 implementation (Vaden/Shelf). Additional Dart REST frameworks should be evaluated.
- **Django**: If using Django REST Framework, this is documented explicitly.
- **Fresh** (Deno): Full-stack framework (Preact), not a pure REST framework. Classified as auxiliary.

## gRPC — Candidate Matrix

| Environment | Option 1 | Option 2 | Option 3 | Notes |
|-------------|----------|----------|----------|-------|
| **Rust** | tonic | Volo gRPC | grpcio-rs | All mature |
| **Go** | grpc-go | ConnectRPC | Kitex | grpc-go is standard |
| **C#/.NET** | gRPC for ASP.NET Core | protobuf-net.Grpc | MagicOnion | |
| **Node.js** | @grpc/grpc-js | nice-grpc | ConnectRPC | |
| **Bun** | @grpc/grpc-js | nice-grpc | ConnectRPC | ⚠️ Experimental (HTTP/2) |
| **Kotlin/JVM** | grpc-kotlin | Spring gRPC | Armeria gRPC | |
| **Deno** | @grpc/grpc-js | nice-grpc | ConnectRPC | ⚠️ Experimental |
| **Python** | grpcio | grpclib | betterproto | betterproto uses grpclib internally |
| **Dart** | grpc-dart | — | — | Only 1 mature server impl |
| **Java/JVM** | grpc-java | Armeria gRPC | Quarkus gRPC | |
| **GraalVM Native** | Quarkus gRPC Native | Micronaut gRPC Native | grpc-java Native | |

### Notes

- **Dart gRPC**: Only `grpc-dart` provides a mature server implementation. Slots without valid implementations are marked `UNAVAILABLE`.
- **betterproto** (Python): Uses `grpclib` as its gRPC engine internally. Document this dependency.
- **Bun/Deno gRPC**: Marked experimental until HTTP/2 compatibility is validated.

## GraphQL — Candidate Matrix

| Environment | Option 1 | Option 2 | Option 3 | Notes |
|-------------|----------|----------|----------|-------|
| **Rust** | async-graphql + Axum | async-graphql + Actix | Juniper | First two share engine (documented) |
| **Go** | gqlgen | graph-gophers/graphql-go | graphql-go/graphql | |
| **C#/.NET** | Hot Chocolate | GraphQL.NET | EntityGraphQL | |
| **Node.js** | Apollo Server | Mercurius | GraphQL Yoga | |
| **Bun** | GraphQL Yoga | Apollo Server | @hono/graphql-server | |
| **Kotlin/JVM** | GraphQL Kotlin | Spring for GraphQL | Netflix DGS | |
| **Deno** | GraphQL Yoga | Apollo Server | @hono/graphql-server | |
| **Python** | Strawberry | Ariadne | Graphene | |
| **Dart** | graphql_server2 | Angel3 GraphQL | Leto | |
| **Java/JVM** | Spring for GraphQL | Netflix DGS | SmallRye GraphQL | |
| **GraalVM Native** | SmallRye GraphQL Native | Spring for GraphQL Native | Micronaut GraphQL Native | |

### Notes

- **Rust async-graphql**: The Axum and Actix integrations share the same GraphQL engine. This is an HTTP integration difference, not independent engines. Documented.
- **GraphQL benchmark rules**: Use fixed POST documents, disable playground/tracing/introspection.

## Implementation Status Summary

| Protocol | Planned | Implemented | Missing |
|----------|---------|-------------|---------|
| REST | 36 | 34 | 2 (C# Controllers, C# FastEndpoints) |
| gRPC | 33 | 0 | 33 |
| GraphQL | 33 | 0 | 33 |
| **Total** | **102** | **34** | **68** |

---

**Last Updated**: 2026-07-28
