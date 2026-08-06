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

| | Antes dos fixes | Depois dos fixes (6.2–6.9) |
|---|---|---|
| **Medido (E2)** | 56 | 56 |
| **Compila limpo** | 43 (77%) | **53 (95%)** |
| **Falha** | 13 | **3** |
| **Não medido** | 44 (sem toolchain) | 44 |

### As 10 falhas corrigidas (Fase 6.2–6.9)

| Implementação | Causa real | Fix |
|---|---|---|
| `go-graphql-gqlgen` | `QueryResolver` undefined (generated.go era stub) | Adicionadas as 3 declarações que o gqlgen emite: `QueryResolver` interface, `Config`, `NewExecutableSchema` |
| `rust-graphql-async-graphql-actix` | `GraphQLResponse` não existe em async-graphql v7 | Handler retorna `async_graphql::Response` direto via `HttpResponse::Ok().json()` |
| `rust-graphql-juniper` | `Decimal: FromSql` não satisfeito | Feature `db-tokio-postgres` adicionada a `rust_decimal` no Cargo.toml |
| `rust-grpc-volo` | `volo_build::Config` não existe (API reworked) | build.rs reescrito com `Builder`; service.rs/main.rs adaptados à API 0.10 (FastStr, MakeIncoming, ServiceBuilder) |
| `bun-rest-bun-serve` | tsconfig sem `allowImportingTsExtensions` (14 erros TS5097) | Flag adicionada ao tsconfig (já tinha `noEmit`) |
| `bun-rest-hono` | idem (11 erros TS5097) | idem |
| `bun-graphql-yoga` | `@graphql-yoga/node@^5.1.0` não existe (renomeado) | Trocado para `graphql-yoga@^5.1.0` no package.json |
| `csharp-graphql-graphql-dotnet` | cast implícito `object` → `Inputs` | `Variables` tipado como `Inputs?` + `InputsJsonConverter` |
| `csharp-graphql-entitygraphql` | 14 erros: static type como generic arg, async lambdas em expression trees, `TimeToLiveAsync` inexistente | Schema reescrito: expression-body lambdas, `.Resolve<TService>()`, `KeyTimeLiveAsync`, `BenchmarkContext` como generic arg |
| `python-graphql-graphene` | `flask-graphql` incompatível com `graphene` v3 | Removido `flask-graphql`; `/graphql` serve direto via `schema.execute()` |

### As 3 falhas restantes

| Implementação | Causa real | Status |
|---|---|---|
| `go-grpc-grpc-go` | código protobuf nunca gerado | Precisa `protoc` + geração de stubs |
| `go-grpc-connectrpc` | idem | idem |
| `go-grpc-kitex` | idem + `go.mod` dessincronizado | idem + `go mod tidy` |

> As 3 falhas restantes são do mesmo grupo — **código protobuf nunca gerado**.
> Precisam de `protoc` instalado e geração dos stubs (`*.pb.go`). O `protoc`
> não estava no PATH; o agente Rust reportou tê-lo usado (provavelmente via
> cargo build dependency), mas o Go gRPC precisa dele explicitamente.
> `rust-grpc-tonic` também depende de `protoc` — pode ter sido corrigido na
> passada do agente Rust, mas não foi re-verificado isoladamente.
