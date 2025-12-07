# API REST Multi-Language Benchmark

## 📊 Visão Geral

Benchmark abrangente e comparativo de performance de frameworks REST API em múltiplas linguagens de programação, focado em cenários de **alta performance**.

### 🎯 Objetivo

Comparar performance entre diferentes linguagens e frameworks, identificando:
- Throughput (requests/segundo)
- Latência (p50, p95, p99)
- Memory footprint
- Cold start time
- Trade-offs performance vs. facilidade de desenvolvimento

## 🏗️ Arquitetura

### Infraestrutura Pré-Configurada
- **PostgreSQL**: `spsql.home.arpa:5432` (database: `benchmark_api`)
- **Redis**: `redis.home.arpa:30379`
- **Kubernetes**: 5 réplicas por serviço

### Dados de Teste
- **10.000 usuários**
- **50.000 pedidos**
- **200.000 itens de pedido**

## 🌐 Tecnologias Suportadas

### Implementações em Progresso

| Linguagem | Framework | Status | Performance |
|-----------|-----------|--------|-------------|
| **C# (.NET 9)** | Minimal API + Dapper + **Native AOT** | ✅ **Concluído** | ⭐⭐⭐⭐⭐ |
| Rust (stable) | Actix Web | 🔄 Próximo | ⭐⭐⭐⭐⭐ |
| Java (21+) | Quarkus + GraalVM Native | 🔄 Próximo | ⭐⭐⭐⭐⭐ |
| Go (1.23+) | Fiber | 📋 Planejado | ⭐⭐⭐⭐ |
| Kotlin | Ktor | 📋 Planejado | ⭐⭐⭐⭐ |
| Node.js (22+) | Fastify | 📋 Planejado | ⭐⭐⭐⭐ |
| Python (3.12+) | FastAPI | 📋 Planejado | ⭐⭐⭐ |
| Bun (1.x) | Elysia | 📋 Planejado | ⭐⭐⭐⭐ |
| Deno (2.x) | Oak | 📋 Planejado | ⭐⭐⭐ |
| Dart (3.x) | Vaden | 📋 Planejado | ⭐⭐⭐ |
| GraalVM (21+) | Vert.x | 📋 Planejado | ⭐⭐⭐⭐⭐ |

## 🔌 Endpoints Obrigatórios

Todos os serviços implementam os mesmos 5 endpoints:

### 1. GET /health
Health check simples
```json
{ "status": "ok", "timestamp": "2025-12-07T10:00:00Z" }
```

### 2. GET /json
Serialização JSON com 1000 objetos
```json
{
  "items": [
    {
      "id": 1,
      "uuid": "...",
      "name": "User 1",
      "email": "user1@example.com",
      "createdAt": "...",
      "isActive": true
    }
    // ... 1000 items
  ]
}
```

### 3. GET /db/simple?id={id}
Query simples no banco (SELECT por ID)
```json
{
  "id": 1,
  "name": "John Smith",
  "email": "user1@example.com",
  "createdAt": "...",
  "isActive": true
}
```

### 4. GET /db/complex?days=30
Query complexa com JOIN e agregação (últimos N dias)
```json
{
  "period_days": 30,
  "total_users": 100,
  "data": [
    {
      "userId": 1,
      "userName": "John Smith",
      "totalOrders": 15,
      "totalValue": 1250.50,
      "averageOrderValue": 83.37
    }
    // ... top 100 users
  ]
}
```

### 5. GET /cache?key={key}
Operações Redis (GET/SET com cache)
```json
{
  "key": "test",
  "value": "Cached value for test at 2025-12-07T10:00:00Z",
  "cached": true,
  "timestamp": "..."
}
```

## 🚀 Quick Start

### 1. Setup Database
```bash
make setup-database
```

### 2. Build & Deploy C# (Minimal API)
```bash
make build-csharp
make deploy-csharp
```

### 3. Run Benchmarks
```bash
# wrk benchmark (30s, 200 connections)
make benchmark-csharp

# Or run individually
./scripts/benchmark-wrk.sh csharp-minimalapi

# k6 benchmark (50 VUs, 60s)
./scripts/benchmark-k6.sh csharp-minimalapi
```

### 4. Collect System Metrics
```bash
make collect-metrics
```

### 5. View Results
```bash
# wrk results
cat results/wrk/*/health.txt

# k6 results
cat results/k6/*/results.json

# System metrics
cat results/metrics/*/summary.txt
```

## 📁 Estrutura do Projeto

```
benchmark-api/
├── README.md                          # Este arquivo
├── Makefile                           # Automação de builds e testes
├── sql/                               # Scripts SQL
│   ├── 01_schema.sql                  # Schema do banco
│   ├── 02_seed.sql                    # Seed com dados
│   └── 03_indexes.sql                 # Índices otimizados
├── src/                               # Implementações por linguagem
│   └── csharp/
│       └── MinimalApi/
│           ├── Program.cs             # Minimal API principal
│           ├── Models/                # Modelos de dados
│           ├── Handlers/              # Handlers dos endpoints
│           ├── Services/              # Database + Cache
│           ├── Dockerfile             # Multi-stage + Native AOT
│           ├── benchmark-api.csproj   # Projeto .NET 9
│           ├── appsettings.json       # Configurações
│           └── k8s/                   # Manifests Kubernetes
│               ├── deployment.yaml    # 5 réplicas
│               ├── service.yaml       # Service ClusterIP
│               └── configmap.yaml     # Configurações
├── scripts/                           # Scripts de automação
│   ├── setup-database.sh              # Setup PostgreSQL
│   ├── benchmark-wrk.sh               # wrk benchmark
│   ├── benchmark-k6.sh                # k6 benchmark
│   ├── k6-benchmark.js                # k6 scenarios
│   └── collect-metrics.sh             # Coleta métricas sistema
├── results/                           # Resultados dos benchmarks
│   ├── wrk/                           # Resultados wrk
│   ├── k6/                            # Resultados k6
│   └── metrics/                       # Métricas do sistema
└── docs/                              # Documentação
    ├── API_ENDPOINTS.md               # Documentação endpoints
    ├── DEPLOYMENT_GUIDE.md            # Guia de deployment
    └── BENCHMARK_RESULTS.md           # Resultados e análise
```

## 🔧 Comandos Detalhados

### Database
```bash
# Setup completo (schema + seed + índices)
make setup-database

# Ou manualmente
psql -h spsql.home.arpa -U app -d benchmark_api -f sql/01_schema.sql
psql -h spsql.home.arpa -U app -d benchmark_api -f sql/02_seed.sql
psql -h spsql.home.arpa -U app -d benchmark_api -f sql/03_indexes.sql
```

### C# (.NET 9)
```bash
# Build com Native AOT
make build-csharp

# Test local
make test-csharp

# Deploy Kubernetes
make deploy-csharp

# Remove do Kubernetes
make undeploy-csharp

# Benchmark completo
make benchmark-csharp
```

### Docker
```bash
# Build imagem
make docker-build-csharp

# Push para registry
make docker-push-csharp
```

### Resultados
```bash
# Status dos pods
make status

# Coleta métricas
make collect-metrics

# Clean everything
make clean-all
```

## 📊 Métricas Coletadas

### Performance
- **Throughput**: Requests/segundo
- **Latência**: p50, p95, p99, p99.9 (wrk)
- **Error Rate**: % de falhas (k6)
- **Concurrent Users**: VUs (k6)

### Recursos
- **Memory Footprint**: MB por pod
- **CPU Utilization**: % de uso
- ** ms por queryDatabase Query Time**:
- **Cold Start**: Tempo de inicialização

### Benchmarks
- **wrk**: Load test multi-threaded
  ```bash
  wrk -t8 -c200 -d30s --latency http://service/health
  ```
- **k6**: Testes com thresholds
  ```bash
  k6 run --vus 50 --duration 60s scripts/k6-benchmark.js
  ```

## 🐳 Docker

### C# (.NET 9) - Native AOT
```dockerfile
# Multi-stage build otimizado
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS builder
# Build com Native AOT
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0
# Runtime minimal com Native AOT
```

**Características:**
- ✅ Binary único estático
- ✅ Native AOT (sem JIT)
- ✅ Startup instantâneo
- ✅ Memory footprint baixo
- ✅ Health check integrado

## ☸️ Kubernetes

### Deployment
- **5 réplicas** por padrão
- **Resources**: 128Mi-512Mi memory, 100m-500m CPU
- **Health Checks**: Liveness + Readiness probes
- **Security**: Non-root user, read-only root filesystem

### Service
- **ClusterIP** para comunicação interna
- **Headless** service para discovery

### ConfigMap
- Database connection string
- Redis connection string
- Environment variables

## 📈 Roadmap

### Fase 1: C# (.NET 9) - ✅ CONCLUÍDO
- [x] Minimal API + Dapper
- [x] Native AOT
- [x] Scripts SQL completos
- [x] Dockerfile multi-stage
- [x] Manifests K8s
- [x] Benchmarks wrk + k6

### Fase 2: Rust + Actix Web (🔄 PRÓXIMO)
- [ ] Implementação dos 5 endpoints
- [ ] Docker optimized
- [ ] K8s manifests
- [ ] Benchmarks

### Fase 3: Java + Quarkus + GraalVM
- [ ] Native Image
- [ ] Reactive programming
- [ ] Performance tuning

### Fase 4: Go + Fiber
- [ ] Concurrency patterns
- [ ] Memory efficiency
- [ ] Deployment

### Fase 5-11: Outras Linguagens
- Kotlin (Ktor)
- Node.js (Fastify)
- Python (FastAPI)
- Bun (Elysia)
- Deno (Oak)
- Dart (Vaden)
- GraalVM (Vert.x)

## 🤝 Contribuindo

Para adicionar uma nova linguagem:

1. Crie diretório: `src/{linguagem}/{framework}/`
2. Implemente os 5 endpoints obrigatórios
3. Adicione Dockerfile multi-stage otimizado
4. Crie manifests K8s (deployment, service, configmap)
5. Teste com `make benchmark-{linguagem}`
6. Atualize este README

## 📄 Licença

MIT License - Veja LICENSE para detalhes

## 👨‍💻 Autor

Principal Software Engineer & SRE Specialist

---

**⭐ Performance-driven. Production-ready. Benchmark-grade. ⭐**
