# API Benchmark — REST, gRPC & GraphQL

Comparativo de desempenho de **101 implementações** em **11 ambientes tecnológicos** e **3 protocolos**.

## 📊 Resumo

| Protocolo | Implementações | Status |
|-----------|---------------|--------|
| REST | 36 | ✅ |
| gRPC | 33 | ✅ |
| GraphQL | 32 | ✅ |
| **Total** | **101** | ✅ |

## 🌐 Ambientes

| Ambiente | REST | gRPC | GraphQL | Total |
|----------|------|------|---------|-------|
| Rust | 4 | 3 | 3 | 10 |
| Go | 4 | 3 | 3 | 10 |
| C#/.NET | 3 | 3 | 3 | 9 |
| Node.js | 3 | 3 | 3 | 9 |
| Bun | 3 | 3 | 3 | 9 |
| Deno | 4 | 3 | 3 | 10 |
| Python | 3 | 3 | 3 | 9 |
| Dart | 1 | 1 | 3 | 5 |
| Java/JVM | 3 | 4 | 2 | 9 |
| Kotlin/JVM | 3 | 3 | 3 | 9 |
| GraalVM Native | 5 | 3 | 3 | 11 |

## 📋 Contratos

### REST — 5 Endpoints

| Endpoint | Descrição |
|----------|-----------|
| `GET /health` | Health check |
| `GET /json` | Serialização de 1000 objetos |
| `GET /db/simple?id=1` | Query simples (PostgreSQL) |
| `GET /db/complex?days=30` | Query complexa com JOIN |
| `GET /cache?key=X` | Cache hit/miss (Redis) |

### gRPC

Contrato: `contracts/grpc/benchmark.proto`

```protobuf
service BenchmarkService {
  rpc Health(HealthRequest) returns (HealthResponse);
  rpc GetJsonItems(JsonItemsRequest) returns (JsonItemsResponse);
  rpc GetUser(GetUserRequest) returns (UserResponse);
  rpc GetComplexOrders(ComplexOrdersRequest) returns (ComplexOrdersResponse);
  rpc GetCacheValue(CacheRequest) returns (CacheResponse);
}
```

### GraphQL

Schema: `contracts/graphql/schema.graphql`

```graphql
type Query {
  health: Health!
  jsonItems(limit: Int = 1000): JsonItemsResult!
  user(id: Int!): User
  complexOrders(days: Int = 30): ComplexOrdersResult!
  cache(key: String!): CacheEntry!
}
```

## 🏗️ Infraestrutura

- **PostgreSQL**: `spsql.home.arpa:5432` (10k users, 50k orders, 200k items)
- **Redis**: `redis.home.arpa:30379`
- **Kubernetes**: K3s, namespace `benchmark`
- **Load Testing**: wrk (REST), k6 (REST/GraphQL), ghz (gRPC)

## 🏷️ Identificador Único

Cada implementação possui um ID: `<ambiente>-<protocolo>-<framework>`

Exemplos:
- `rust-rest-actix-web`
- `go-grpc-grpc-go`
- `nodejs-graphql-mercurius`
- `dart-rest-vaden`
- `graalvm-graphql-smallrye`

## 🚀 Comandos

```bash
# Listar todas as 101 implementações
make inventory

# Build por implementation ID
make build IMPL=rust-grpc-tonic

# Deploy em modo single-pod
make deploy IMPL=go-graphql-gqlgen MODE=single-pod

# Smoke test
make smoke IMPL=nodejs-graphql-mercurius

# Benchmark
make benchmark IMPL=python-grpc-grpcio SCENARIO=health MODE=clusterip

# Undeploy
make undeploy IMPL=csharp-rest-controllers

# Preflight check (PostgreSQL + Redis)
make preflight
```

## 📈 Modos de Benchmark

| Modo | Réplicas | Acesso | Objetivo |
|------|----------|--------|----------|
| A — Pod Single | 1 | Direto | Comparação entre frameworks |
| B — ClusterIP | 1 | Service | Custo do Service/CoreDNS |
| C — Scale-Out | 5 | Service | Escalabilidade horizontal |

## 📁 Estrutura

```
benchmark/
├── config/implementations.yaml    # Fonte de verdade (101 impls)
├── contracts/
│   ├── grpc/benchmark.proto       # Contrato gRPC
│   └── graphql/schema.graphql     # Schema GraphQL
├── deploy/k3s/
│   ├── base/                      # Kustomize base
│   ├── overlays/                  # Overlays por protocolo
│   ├── loadgen/                   # Jobs wrk/ghz/k6
│   └── preflight/                 # Job de validação
├── docs/                          # Documentação
├── scripts/                       # Scripts genéricos
├── src/                           # 11 ambientes × 3 protocolos
│   ├── rust/     (4+3+3 = 10)
│   ├── go/       (4+3+3 = 10)
│   ├── csharp/   (3+3+3 = 9)
│   ├── nodejs/   (3+3+3 = 9)
│   ├── bun/      (3+3+3 = 9)
│   ├── deno/     (4+3+3 = 10)
│   ├── python/   (3+3+3 = 9)
│   ├── dart/     (1+1+3 = 5)
│   ├── java/     (3+4+2 = 9)
│   ├── kotlin/   (3+3+3 = 9)
│   └── graalvm/  (5+3+3 = 11)
├── sql/                           # Schema, seed, indexes
├── kubernetes/secrets.example.yaml
└── Makefile
```

## 📚 Documentação

| Documento | Descrição |
|-----------|-----------|
| [SECURITY_REMEDIATION.md](docs/SECURITY_REMEDIATION.md) | Plano de rotação de credenciais |
| [PROJECT_INVENTORY.md](docs/PROJECT_INVENTORY.md) | Inventário completo de 101 implementações |
| [FRAMEWORK_MATRIX.md](docs/FRAMEWORK_MATRIX.md) | Matriz de frameworks por ambiente |
| [API_CONTRACTS.md](docs/API_CONTRACTS.md) | Contratos REST/gRPC/GraphQL |
| [BENCHMARK_METHODOLOGY.md](docs/BENCHMARK_METHODOLOGY.md) | Metodologia científica |
| [RESULTS_SCHEMA.md](docs/RESULTS_SCHEMA.md) | Schema JSON dos resultados |

## ⚠️ Segurança

O arquivo `kubernetes/secrets.yaml` contém credenciais em texto aberto.
Consulte [SECURITY_REMEDIATION.md](docs/SECURITY_REMEDIATION.md) para o plano de remediação.

Use `kubernetes/secrets.example.yaml` como template seguro.

## 📊 Resultados

Resultados serão classificados como:
- **MEASURED**: Dados reais coletados
- **ESTIMATED**: Valores projetados
- **EXEMPLO**: Template/formato

Rankings separados por protocolo, modo e cenário.

## Licença

MIT
