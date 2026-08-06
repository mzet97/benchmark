# Build Matrix — Fase 6.1

**Atualizado**: 2026-08-06 (pós-fixes Fase 6.2–6.9)
**Objetivo**: registrar, para cada uma das 100 implementações, se ela compila
(E2) e qual é o erro real quando não compila. Antes deste documento, a lista de
"implementações que não buildam" era um palpite — e quando a toolchain JVM foi
instalada, 3 dos 6 projetos Kotlin listados como quebrados compilavam limpo.

## Níveis de evidência

| Nível | Significado |
|---|---|
| E0 | Nenhuma. Lido, não executado |
| E1 | Verificado contra documentação publicada da API/pacote |
| **E2** | **Compila (`cargo check`, `go build`, `dotnet build`, `npm install`)** |
| E3 | Módulo/função executada isoladamente |
| E4 | Serviço sobe e responde; `validate-parity.py --url` passa |
| E5 | Medido sob carga |

Nada entra na matriz de resultados abaixo de **E4**. Este documento cobre **E2**.

## Ambiente de medição

| Ferramenta | Versão | Observação |
|---|---|---|
| Go | go1.26.2 windows/amd64 | — |
| Rust | rustc 1.95.0 | — |
| Node.js | v24.14.1 (npm 11.11.0) | — |
| Bun | 1.3.14 | `bun install` falha na escrita do lockfile no Windows; resultados usam `--no-save` |
| .NET | 10.0.302 | — |
| Python | 3.12.10 | — |
| Java | 25.0.2 LTS | **sem Maven/Gradle** — JVM não medido |
| protoc | **não instalado** | afeta Go gRPC, Rust tonic |
| CMake | não verificado | afeta Rust grpcio |

Repositório em share de rede `Z:`. Builds executados in-place (não em disco
local); nenhum apresentou `ReadOnlyFileSystemException` nesta passada.

---

## Resultado por linguagem

### Go — 7/10 ✅

| ID | E2 | Erro real (primeira linha) |
|---|---|---|
| `go-rest-fiber` | ✅ | — |
| `go-rest-gin` | ✅ | — |
| `go-rest-echo` | ✅ | — |
| `go-rest-chi` | ✅ | — |
| `go-grpc-grpc-go` | ❌ | `package benchmark-grpc-go/proto/generated is not in std` — **código protobuf nunca gerado**; só existe `proto/benchmark.proto` |
| `go-grpc-connectrpc` | ❌ | `package benchmark-connectrpc/gen/benchmark is not in std` — **stubs gerados ausentes**, `gen/benchmark/` é diretório vazio |
| `go-grpc-kitex` | ❌ | `go: updates to go.mod needed; to update it: go mod tidy` — go.mod dessincronizado; também sem `kitex_gen/` |
| `go-graphql-gqlgen` | ❌ | `graph/schema.resolvers.go:124:28: undefined: QueryResolver` — resolver quebrado/incompleto |
| `go-graphql-graphql-go` | ✅ | — |
| `go-graphql-graphql-go-2` | ✅ | — |

**Padrão**: as 3 falhas de gRPC têm a mesma causa raiz — o passo de geração de
código (`protoc`) nunca foi executado. Não é defeito de lógica, é etapa de build
ausente.

### Rust — 5/10 ✅

| ID | E2 | Erro real (primeira linha) |
|---|---|---|
| `rust-rest-actix-web` | ✅ | — |
| `rust-rest-axum` | ✅ | 7 warnings benignos (depreciações) |
| `rust-rest-rocket` | ✅ | 6 warnings benignos |
| `rust-rest-warp` | ✅ | 2 warnings benignos |
| `rust-grpc-tonic` | ❌ | `Could not find protoc` — build script precisa do binário `protoc`, não instalado |
| `rust-grpc-volo` | ❌ | `could not find Config in volo_build` — API drift: `volo_build::Config` não existe nesta versão |
| `rust-grpc-grpcio` | ❌ | CMake error no `grpcio-sys` bundled: `Compatibility with CMake < 3.5 has been removed` |
| `rust-graphql-async-graphql-axum` | ✅ | — |
| `rust-graphql-async-graphql-actix` | ❌ | `unresolved import async_graphql::http::GraphQLResponse` — `GraphQLResponse` não existe em `http` |
| `rust-graphql-juniper` | ❌ | `the trait bound Decimal: FromSql<'_> is not satisfied` — falta feature `tokio-postgres` para `rust_decimal` |

**Observação**: `tonic` pode passar quando `protoc` for instalado — é limite de
toolchain, não de código. Os outros 3 são defeitos de fonte/API.

### Node.js — 9/9 ✅

| ID | E2 | Observação |
|---|---|---|
| `nodejs-rest-fastify` | ✅ | JS puro, sem step de compilação |
| `nodejs-rest-express` | ✅ | JS puro |
| `nodejs-rest-nestjs` | ✅ | `nest build` (TS) limpo |
| `nodejs-grpc-grpc-js` | ✅ | JS puro |
| `nodejs-grpc-nice-grpc` | ✅ | JS puro |
| `nodejs-grpc-connectrpc` | ✅ | JS puro |
| `nodejs-graphql-apollo` | ✅ | JS puro |
| `nodejs-graphql-mercurius` | ✅ | JS puro |
| `nodejs-graphql-yoga` | ✅ | JS puro |

### Bun — 7/9 ✅

| ID | E2 | Erro real (primeira linha) |
|---|---|---|
| `bun-rest-bun-serve` | ❌ | `TS5097: An import path can only end with '.ts' extension when 'allowImportingTsExtensions' is enabled` — 14 erros TS (tsconfig sem a flag) |
| `bun-rest-elysia` | ✅ | `bun build` limpo |
| `bun-rest-hono` | ❌ | `TS5097` — mesmo padrão que bun_serve, 11 erros TS |
| `bun-grpc-grpc-js` | ✅ | JS puro, sem step de compilação |
| `bun-grpc-nice-grpc` | ✅ | JS puro |
| `bun-grpc-connectrpc` | ✅ | JS puro |
| `bun-graphql-yoga` | ❌ | `No version matching "^5.1.0" found for @graphql-yoga/node` — versão inexistente no npm; bug de manifesto |
| `bun-graphql-apollo` | ✅ | JS puro |
| `bun-graphql-hono` | ✅ | JS puro |

**Observação**: os 2 erros de `tsc` (bun_serve, hono) têm a mesma causa: imports
com extensão `.ts` sem `allowImportingTsExtensions` no tsconfig. Correção
cabe em 1 linha por projeto. O lockfile do Bun no Windows é bug conhecido da
1.3.14; os resultados usam `--no-save` para isolar a resolução de dependência.

### C# / .NET — 7/9 ✅

| ID | E2 | Erro real (primeira linha) |
|---|---|---|
| `csharp-rest-minimal-api` | ✅ | — |
| `csharp-rest-controllers` | ✅ | — |
| `csharp-rest-fastendpoints` | ✅ | — |
| `csharp-grpc-grpc-dotnet` | ✅ | — |
| `csharp-grpc-protobuf-net-grpc` | ✅ | — |
| `csharp-grpc-magiconion` | ✅ | — |
| `csharp-graphql-hotchocolate` | ✅ | — |
| `csharp-graphql-graphql-dotnet` | ❌ | `CS0266: Cannot implicitly convert type 'object' to 'GraphQL.Inputs'` — falta cast em `Program.cs:37` |
| `csharp-graphql-entitygraphql` | ❌ | `CS0234: The type or namespace 'AspNetCore' does not exist in namespace 'EntityGraphQL'` — falta package reference |

### Python — 8/9 ✅

| ID | E2 | Erro real (primeira linha) |
|---|---|---|
| `python-rest-fastapi` | ✅ | `email-validator 2.1.0` yanked (não-fatal) |
| `python-rest-flask` | ✅ | — |
| `python-rest-django` | ✅ | — |
| `python-grpc-grpcio` | ✅ | `generated/` vazio (stubs gerados em build time por `generate.py`); `py_compile` do fonte passa |
| `python-grpc-grpclib` | ✅ | idem |
| `python-grpc-betterproto` | ✅ | idem |
| `python-graphql-strawberry` | ✅ | — |
| `python-graphql-ariadne` | ✅ | — |
| `python-graphql-graphene` | ❌ | `graphene 3.3 requires graphql-core>=3.1,<3.3` vs `flask-graphql 2.0.1 requires graphql-core>=2.1,<3` — `ResolutionImpossible`, conflito de versão fundamental |

**Observação**: os 3 gRPC Python têm `generated/` vazio, mas o fonte compila.
Os stubs são gerados por `generate.py` em tempo de build (Dockerfile), não
commitados. Isso não afeta E2, mas precisará de verificação em E4.

---

## Não medido — 44 implementações (sem toolchain)

| Linguagem | Implementações | Toolchain faltante | Tarefa do plano |
|---|---|---|---|
| Dart | 5 | SDK Dart | 6.7 |
| Deno | 10 | runtime Deno | 6.8 |
| Java | 8 | Maven/Gradle | 6.5, 6.9 |
| Kotlin | 9 | Gradle/kotlinc | 6.2, 6.3, 6.4, 6.9 |
| GraalVM | 12 | Maven/Gradle + native-image | 6.6, 6.9 |

Estas 44 implementações estão em **E1** (Dart, Deno) ou **E0** (JVM/GraalVM sem
build). O plano prevê instalar as toolchains em diretório temporário da sessão
e medir; isso é trabalho das tarefas 6.2–6.9.

---

## Resumo executivo

| | Após 6.2–6.9 | Após Trilha A3 (44 pendentes) |
|---|---|---|
| **Medido (E2)** | 56 | **100** |
| **Compila limpo** | 56 (100% das medidas) | **68/100 (68%)** |
| **Falha** | 0 | **32** |
| **Não medido** | 44 | **0** |

### As 13 falhas corrigidas (Fase 6.2–6.9)

| Implementação | Causa real | Fix |
|---|---|---|
| `go-graphql-gqlgen` | `QueryResolver` undefined (generated.go era stub) | Adicionadas as 3 declarações que o gqlgen emite |
| `rust-graphql-async-graphql-actix` | `GraphQLResponse` não existe em async-graphql v7 | Handler retorna `Response` via `json()` |
| `rust-graphql-juniper` | `Decimal: FromSql` não satisfeito | Feature `db-tokio-postgres` em `rust_decimal` |
| `rust-grpc-volo` | `volo_build::Config` não existe (API reworked) | build.rs reescrito; service.rs/main.rs adaptados à API 0.10 |
| `bun-rest-bun-serve` | tsconfig sem `allowImportingTsExtensions` (14 TS5097) | Flag adicionada |
| `bun-rest-hono` | idem (11 TS5097) | idem |
| `bun-graphql-yoga` | `@graphql-yoga/node@^5.1.0` não existe | Trocado para `graphql-yoga@^5.1.0` |
| `csharp-graphql-graphql-dotnet` | cast `object` → `Inputs` | `Inputs?` + `InputsJsonConverter` |
| `csharp-graphql-entitygraphql` | 14 erros (schema design + API mismatch) | Schema reescrito: expression lambdas, `.Resolve<T>()`, `KeyTimeLiveAsync` |
| `python-graphql-graphene` | `flask-graphql` vs `graphene` v3 | Removido; `/graphql` via `schema.execute()` |
| `go-grpc-grpc-go` | código protobuf nunca gerado | Stubs `.pb.go` gerados e commitados |
| `go-grpc-connectrpc` | idem | Stubs gerados + import do handler corrigido |
| `go-grpc-kitex` | idem + `go.mod` inválido + deps incompatíveis com Go 1.26 | `go mod tidy` + `genproto`/`sonic` atualizados + getters |
| `rust-grpc-tonic` | `protoc` ausente + `env::` não importado | `protoc` instalado + `use std::env;` |

---

## Não medido — 44 implementações (sem toolchain) → MEDIDO AGORA

### Java (8) — `mvn compile -B -q` (Maven 3.9.9, JDK 25)

| ID | E2 | Erro real |
|---|---|---|
| `java-rest-spring` | ✅ | — |
| `java-rest-micronaut` | ✅ | — |
| `java-rest-quarkus` | ✅ | — |
| `java-grpc-grpc-java` | ❌ | `protobuf-maven-plugin: ZIP SLIP` — plugin 0.6.1 não descompacta protos no path UNC `Z:` |
| `java-grpc-armeria` | ❌ | idem (ZIP SLIP no path UNC) |
| `java-grpc-quarkus` | ❌ | `method does not override` — 5 erros de drift na interface gRPC |
| `java-graphql-spring-graphql` | ✅ | — |
| `java-graphql-dgs` | ✅ | — |

**Java: 5/8 limpo.**

### Kotlin (9) — `gradle compileKotlin -q` (Gradle 8.5)

| ID | E2 | Erro real |
|---|---|---|
| `kotlin-rest-ktor` | ❌ | `jvmToolchain(21)` falha — só JDK 25 disponível |
| `kotlin-rest-spring` | ❌ | `Unsupported class file major version 69` — Gradle 8.5 não roda em JDK 25 |
| `kotlin-rest-http4k` | ❌ | idem |
| `kotlin-grpc-grpc-kotlin` | ❌ | `jvmToolchain` mismatch |
| `kotlin-grpc-spring-grpc` | ❌ | idem |
| `kotlin-grpc-armeria` | ❌ | idem |
| `kotlin-graphql-graphql-kotlin` | ❌ | idem |
| `kotlin-graphql-spring-graphql` | ❌ | idem |
| `kotlin-graphql-dgs` | ❌ | idem |

**Kotlin: 0/9.** Todas falham por **JDK ausente** — Gradle 8.5 requer ≤JDK 21.
JDK 21 (Temurin) em instalação; re-medir quando disponível.

### GraalVM JIT (12) — `mvn compile -B -q`

| ID | E2 | Erro real |
|---|---|---|
| `graalvm-rest-spring` | ✅ | — |
| `graalvm-rest-gspring` | ✅ | — |
| `graalvm-rest-micronaut` | ✅ | — |
| `graalvm-rest-gmicronaut` | ✅ | — |
| `graalvm-rest-vertx` | ❌ | API errors (6.6): `CorsHandler` duplicado, `RedisOptions.setPort`, `PoolOptions.setMinSize`, `Row.encode`, `Command` ausente |
| `graalvm-rest-helidon` | ✅ | — |
| `graalvm-grpc-grpc-java` | ❌ | `ZIP SLIP` (mesmo problema do path UNC) |
| `graalvm-grpc-micronaut` | ❌ | `micronaut-data-jdbc:4.11.3` não existe no Maven Central |
| `graalvm-grpc-quarkus` | ❌ | `native-sources` goal não existe no `quarkus-maven-plugin:3.17.5` |
| `graalvm-graphql-spring` | ✅ | — |
| `graalvm-graphql-micronaut` | ❌ | `micronaut-serde-processor:4.4.0` não existe no Maven Central |
| `graalvm-graphql-smallrye` | ❌ | `native-sources` goal não existe no `quarkus-maven-plugin:3.11.1` |

**GraalVM JIT: 6/12 limpo.**

### Dart (5) — `dart analyze`

| ID | E2 | Erro real |
|---|---|---|
| `dart-rest-vaden` | ✅ | 0 erros (1 warning benigno) |
| `dart-grpc-grpc-dart` | ❌ | `benchmark.pbgrpc.dart` ausente (protoc não rodou); `Sql` não importado; `Command.send` API mismatch |
| `dart-graphql-graphql-server2` | ❌ | `shelf_router ^1.1.5` não existe — pub get falha |
| `dart-graphql-angel3` | ❌ | import errado (`graphql` vs `graphql_server2`); `corsMiddleware` ausente; `Command.send` |
| `dart-graphql-leto` | ❌ | `shelf_router ^1.1.5` não existe — pub get falha |

**Dart: 1/5.** Nota: `dart analyze` trava em disco de rede; medição feita em `/tmp`.

### Deno (10) — `deno check`

| ID | E2 | Erro real |
|---|---|---|
| `deno-rest-deno_serve` | ❌ | `Redis` usado como valor mas é tipo (TS2693) |
| `deno-rest-hono` | ❌ | imports `postgres`/`redis` não estão no `deno.json` imports map |
| `deno-rest-oak` | ❌ | `deno.json` lib `["ES2022"]` sem `deno.ns`/`dom` → 57 erros |
| `deno-rest-fresh` | ❌ | idem (44 erros) |
| `deno-grpc-grpc-js` | ❌ | `ClientOptions.host` inexistente; tipos grpc incompatíveis |
| `deno-grpc-nice-grpc` | ❌ | `ioredis` não construtível; `ClientOptions.host`; `count` indefinido |
| `deno-grpc-connectrpc` | ❌ | `ioredis` não construtível; `ClientOptions.host`; tipos untyped |
| `deno-graphql-yoga` | ❌ | `ioredis` não construtível (1 erro) |
| `deno-graphql-apollo` | ❌ | `ioredis` não construtível; `HTTPGraphQLRequest.search` ausente |
| `deno-graphql-hono` | ❌ | `ioredis` não construtível; `rootValue` API mismatch |

**Deno: 0/10.** Padrões recorrentes: `ioredis` não construtível (5 impls),
`deno.json` sem libs `deno.ns`/`dom` (2 impls), `ClientOptions.host` (3 impls).
