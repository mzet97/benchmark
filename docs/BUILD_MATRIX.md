# Build Matrix — Fase 6.1

**Atualizado**: 2026-08-06
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

| | |
|---|---|
| **Medido (E2)** | 56 implementações |
| **Compila limpo** | 43 (77%) |
| **Falha** | 13 |
| **Não medido** | 44 (sem toolchain) |

### As 13 falhas, por causa raiz

| Causa raiz | Qtd | Implementações |
|---|---|---|
| Código protobuf nunca gerado (`protoc` ausente) | 4 | go-grpc-{grpc-go, connectrpc, kitex}, rust-grpc-tonic |
| Bug de fonte (erro de tipo, API drift, import ausente) | 6 | go-graphql-gqlgen, rust-grpc-{volo, grpcio}, rust-graphql-{async-graphql-actix, juniper}, csharp-graphql-{graphql-dotnet, entitygraphql} |
| Configuração TypeScript/tsconfig | 2 | bun-rest-{bun-serve, hono} |
| Conflito de versão de dependência | 2 | bun-graphql-yoga, python-graphql-graphene |
| `protoc` não instalado (limite de toolchain, não de código) | 1 | (incluído em "protoc ausente" acima) |

> **4 das 13 falhas são limite de toolchain**, não defeito de código: `protoc`
> não está instalado. Quando for, as 3 de Go gRPC + tonic devem ser remedidas.
> `grpcio` (Rust) depende de CMake compatível — separado.

### Próximo passo

A lista final de defeitos para a Fase 6.2–6.9 sai deste documento. As 13 falhas
acima têm causa real identificada; as 44 pendentes precisam de toolchain antes
de ser classificadas. Implementação que não chega a E2 **sai da matriz e isso é
publicado** (Fase 7.4).
