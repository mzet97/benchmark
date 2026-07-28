# API REST Multi-Language Benchmark

## 📊 Visão Geral

Benchmark abrangente e comparativo de performance de frameworks REST API em **11 linguagens de programação** e **~35 frameworks**, focado em cenários de **alta performance**.

### 🎯 Objetivo

Comparar performance entre diferentes linguagens e frameworks, identificando:
- Throughput (requests/segundo)
- Latência (p50, p95, p99)
- Memory footprint
- Cold start time
- Trade-offs performance vs. facilidade de desenvolvimento

## 🏗️ Arquitetura

### Infraestrutura
- **PostgreSQL**: `spsql.home.arpa:5432` (database: `benchmark_api`)
- **Redis**: `redis.home.arpa:30379`
- **Kubernetes**: namespace `benchmark`, 5 réplicas por serviço
- **Load Testing**: wrk (8 threads, 200 conexões, 30s) + k6 (50 VUs, 60s)

### Dados de Teste
- **10.000 usuários** | **50.000 pedidos** | **200.000 itens de pedido**

## 🌐 11 Linguagens Implementadas

| Linguagem | Frameworks | Status | Performance |
|-----------|-----------|--------|-------------|
| **C# (.NET 9)** | Minimal API | ✅ Concluído | ⭐⭐⭐⭐⭐ |
| **Rust** | Actix Web, Axum, Rocket, Warp | ✅ Concluído | ⭐⭐⭐⭐⭐ |
| **Java (21+)** | Quarkus, Spring Boot, Micronaut | ✅ Concluído | ⭐⭐⭐⭐⭐ |
| **Go (1.23+)** | Fiber, Gin, Echo, Chi | ✅ Concluído | ⭐⭐⭐⭐⭐ |
| **Kotlin** | Ktor, Spring Boot, http4k | ✅ Concluído | ⭐⭐⭐⭐ |
| **Node.js (22+)** | Fastify, Express, NestJS | ✅ Concluído | ⭐⭐⭐⭐ |
| **Python (3.12+)** | FastAPI, Django, Flask | ✅ Concluído | ⭐⭐⭐ |
| **Bun (1.x)** | Elysia, Hono, Bun.serve | ✅ Concluído | ⭐⭐⭐⭐ |
| **Deno (2.x)** | Oak, Fresh, Hono, Deno.serve | ✅ Concluído | ⭐⭐⭐ |
| **Dart (3.x)** | Shelf | ✅ Concluído | ⭐⭐⭐ |
| **GraalVM (21+)** | Vert.x, Spring, Micronaut, Helidon | ✅ Concluído | ⭐⭐⭐⭐⭐ |

## 🔌 Endpoints Obrigatórios

Todos os serviços implementam os mesmos 5 endpoints:

| Endpoint | Descrição |
|----------|-----------|
| `GET /health` | Health check (DB + Redis) |
| `GET /json` | Serialização JSON (1000 objetos) |
| `GET /db/simple?id={id}` | Query simples (SELECT por ID) |
| `GET /db/complex?days={days}` | Query complexa (JOIN + agregação) |
| `GET /cache?key={key}` | Cache Redis (GET/SET com TTL) |

## 🚀 Quick Start

```bash
# 1. Setup Database
make setup-database

# 2. Build all 11 implementations
make build-all

# 3. Deploy all to Kubernetes
make deploy-all

# 4. Run all benchmarks (long-running)
make benchmark-all

# 5. Check status
make status

# 6. Undeploy all
make undeploy-all
```

### Comandos Individuais

```bash
# Build/deploy/benchmark uma linguagem específica
make build-rust
make deploy-rust
make benchmark-rust
make undeploy-rust

# Listar todas as linguagens disponíveis
make help
```

## 📁 Estrutura do Projeto

```
benchmark/
├── Makefile                    # Automação (build/deploy/benchmark all)
├── README.md                   # Este arquivo
├── FINAL_SUMMARY.md            # Resumo executivo final
├── sql/                        # Schema, seed, índices
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   └── 03_indexes.sql
├── kubernetes/                 # Secrets compartilhados
│   └── secrets.yaml
├── scripts/                    # Scripts de automação
│   ├── deploy-k8s.sh          # Deploy genérico (qualquer linguagem)
│   ├── undeploy-k8s.sh        # Undeploy genérico
│   ├── benchmark-wrk-*.sh     # Benchmarks por linguagem (11)
│   └── benchmark-k6.sh        # Benchmark k6
├── docs/                       # Documentação
│   ├── API_ENDPOINTS.md        # Especificação dos endpoints
│   ├── DEPLOYMENT_GUIDE.md     # Guia de deploy
│   └── BENCHMARK_RESULTS.md   # Resultados
└── src/                        # Implementações
    ├── csharp/MinimalApi/      # C# (.NET 9 Native AOT)
    ├── rust/                   # Rust (4 frameworks)
    ├── java/                   # Java (3 frameworks)
    ├── go/                     # Go (4 frameworks)
    ├── kotlin/                 # Kotlin (3 frameworks)
    ├── nodejs/                 # Node.js (3 frameworks)
    ├── python/                 # Python (3 frameworks)
    ├── bun/                    # Bun (3 frameworks)
    ├── deno/                   # Deno (4 frameworks)
    ├── dart/vaden/             # Dart (Shelf)
    └── graalvm/                # GraalVM (6 frameworks)
```

## 📊 Performance Ranking

| Rank | Linguagem | Startup | Memória | Throughput | Latência |
|------|-----------|---------|---------|------------|----------|
| 🥇 | Go (Fiber) | <10ms | 10-20MB | 500k+/s | <1ms |
| 🥇 | Rust (Actix) | 10-50ms | 10-20MB | 500k+/s | 0.5-1ms |
| 🥈 | GraalVM (Vert.x) | <50ms | 20-50MB | 400k-600k/s | 1-2ms |
| 🥈 | Java (Quarkus) | <50ms | 20-40MB | 400k-500k/s | 1-2ms |
| 🥉 | Bun (Elysia) | 50-200ms | 30-80MB | 400k-600k/s | 1-2ms |
| 6 | C# (.NET AOT) | 50-100ms | 50-80MB | 400k+/s | 1-2ms |
| 7 | Deno (Oak) | 100-300ms | 40-100MB | 300k-500k/s | 1-3ms |
| 8 | Node.js (Fastify) | 100-500ms | 50-100MB | 300k-500k/s | 1-3ms |
| 9 | Dart (Shelf) | 200-500ms | 50-100MB | 300k-500k/s | 2-3ms |
| 10 | Kotlin (Ktor) | 2-3s | 100-200MB | 300k-400k/s | 2-3ms |
| 11 | Python (FastAPI) | 500ms-2s | 50-150MB | 100k-300k/s | 3-5ms |

## ☸️ Kubernetes

Cada implementação inclui:
- **deployment.yaml**: 5 réplicas, health checks (liveness + readiness), resource limits
- **service.yaml**: ClusterIP na porta 80 → targetPort do app
- **configmap.yaml**: Configurações do servidor

```bash
# Deploy de uma linguagem específica
./scripts/deploy-k8s.sh csharp
./scripts/deploy-k8s.sh rust
./scripts/deploy-k8s.sh go

# Undeploy
./scripts/undeploy-k8s.sh csharp

# Status de todos os pods
make status
```

## 📈 Métricas Coletadas

- **Throughput**: Requests/segundo (wrk)
- **Latência**: p50, p95, p99, p99.9
- **Memory Footprint**: MB por pod (kubectl top)
- **CPU Utilization**: % de uso
- **Cold Start**: Tempo de inicialização
- **Error Rate**: % de falhas (k6)

## 🤝 Contribuindo

Para adicionar uma nova linguagem:

1. Crie diretório: `src/{linguagem}/{framework}/`
2. Implemente os 5 endpoints obrigatórios
3. Adicione Dockerfile multi-stage otimizado
4. Crie manifests K8s (deployment, service, configmap)
5. Adicione `build.sh` e `run.sh`
6. Crie `README.md` com documentação
7. Teste com `make benchmark-{linguagem}`

## 📄 Licença

MIT License

---

**⭐ 11 linguagens. ~35 frameworks. Production-ready. Benchmark-grade. ⭐**
