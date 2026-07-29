# Plano de Ação — Benchmark REST/gRPC/GraphQL

**Status atual**: 36/47 pods Running, 32 implementações com primeiro benchmark
**Objetivo**: Benchmark completo com todos os cenários, métricas e rankings

---

## Fase 1 — Corrigir Implementações Not Ready (11 pods)

### 1.1 REST CrashLoopBackOff (4)

| Implementação | Problema | Ação |
|---------------|---------|------|
| bun-rest-hono | Port conflict | Verificar se fix do agente foi aplicado |
| kotlin-rest-ktor | Redis crash | Verificar se fix do agente foi aplicado |
| deno-deno-serve | Old deployment | Remover deployment duplicado |
| bun-rest-bun-serve | ReferenceError | Verificar se fix do agente foi aplicado |

**Comando**:
```bash
# Verificar status
kubectl get pods -n benchmark | grep -E "CrashLoop|Error|Pending"

# Logs de cada pod
kubectl logs -l app=<impl> -n benchmark --tail=20

# Remover deployment antigo duplicado
kubectl delete deployment deno-deno-serve -n benchmark
```

### 1.2 gRPC CrashLoopBackOff (6)

| Implementação | Problema | Ação |
|---------------|---------|------|
| bun-grpc-nice-grpc | TypeError in binding | Corrigir código fonte |
| nodejs-grpc-nice-grpc | TypeError | Corrigir código fonte |
| nodejs-grpc-connectrpc | Package rename | Corrigir import |
| python-grpc-grpclib | ModuleNotFoundError | Corrigir path de import |
| python-grpc-betterproto | Runtime crash | Corrigir dependências |
| deno-grpc-nice-grpc | Runtime crash | Corrigir código |

### 1.3 GraphQL CrashLoopBackOff (1)

| Implementação | Problema | Ação |
|---------------|---------|------|
| python-graphql-ariadne | ImportError | Verificar se fix do agente foi aplicado |

**Execução**: Agente paralelo para corrigir todos os 11 pods

---

## Fase 2 — Benchmark Isolado (uma implementação por vez)

### 2.1 Preparação

```bash
# Undeploy ALL implementations
kubectl delete deployments --all -n benchmark

# Confirmar limpeza
kubectl get pods -n benchmark
```

### 2.2 Protocolo por Implementação

Para cada uma das 32 implementações benchmarkadas:

1. **Deploy** (1 réplica, modo single-pod)
2. **Aguardar readiness** (60s)
3. **Smoke test** (validar contrato)
4. **Warm-up** (30s)
5. **Medição** (5 repetições × 60s)
6. **Coleta de métricas** (CPU, memória)
7. **Undeploy**
8. **Cool-down** (10s)

### 2.3 Cenários por Implementação

| # | Cenário | REST | gRPC | GraphQL |
|---|---------|------|------|---------|
| 1 | Health | /health | Health RPC | { health } |
| 2 | JSON | /json | GetJsonItems | { jsonItems } |
| 3 | DB Simple | /db/simple?id=1 | GetUser | { user(id:1) } |
| 4 | DB Complex | /db/complex?days=30 | GetComplexOrders | { complexOrders } |
| 5 | Cache Hit | /cache?key=bench | GetCacheValue | { cache } |

### 2.4 Concorrência

| Nível | REST (wrk) | gRPC (ghz) | GraphQL (wrk) |
|-------|-----------|-----------|---------------|
| 1 | -t1 -c1 | --concurrency 1 | -t1 -c1 |
| 10 | -t2 -c10 | --concurrency 10 | -t2 -c10 |
| 50 | -t4 -c50 | --concurrency 50 | -t4 -c50 |
| 100 | -t4 -c100 | --concurrency 100 | -t4 -c100 |
| 200 | -t4 -c200 | --concurrency 200 | -t4 -c200 |

**Total por implementação**: 5 cenários × 5 concorrências × 5 repetições = 125 medições
**Total geral**: 32 implementações × 125 = 4.000 medições

---

## Fase 3 — Coleta de Métricas

### 3.1 Métricas por Execução

```bash
# Durante o benchmark, coletar a cada 5s:
kubectl top pod <impl> -n benchmark --containers
```

### 3.2 Métricas Coletadas

| Categoria | Métricas |
|-----------|---------|
| Throughput | req/s, ops/s |
| Latência | p50, p90, p95, p99, p999, max |
| CPU | mean cores, max cores, throttled |
| Memória | RSS mean, RSS max, working set |
| Rede | bytes received, bytes transmitted |
| Erros | error rate, timeouts |
| Kubernetes | pod restarts, OOM kills |

### 3.3 Formato de Saída

Cada execução gera JSON em `results/raw/<run-id>/<impl>/<scenario>/<mode>/c<concurrency>.json`

---

## Fase 4 — Rankings Normalizados

### 4.1 Rankings Separados

| Ranking | Critério |
|---------|---------|
| REST Health Single-Pod | req/s mediana (5 repetições) |
| REST JSON Single-Pod | req/s mediana |
| REST DB-Simple Single-Pod | req/s mediana |
| REST DB-Complex Single-Pod | req/s mediana |
| REST Cache Single-Pod | req/s mediana |
| gRPC Health Single-Pod | ops/s mediana |
| gRPC JSON Single-Pod | ops/s mediana |
| GraphQL Health Single-Pod | req/s mediana |
| GraphQL JSON Single-Pod | req/s mediana |

### 4.2 Estatísticas

Para cada ranking:
- Mediana (principal)
- Média
- Desvio padrão
- Mínimo / Máximo
- Intervalo de confiança 95%

### 4.3 Relatório Final

```
results/reports/
  summary.json
  rankings/
    rest-health-single-pod.json
    rest-json-single-pod.json
    grpc-health-single-pod.json
    graphql-health-single-pod.json
    ...
```

---

## Fase 5 — Correções Pendentes

### 5.1 Implementações com Build Fail (precisam correção de código)

| Ambiente | Frameworks | Problema Típico |
|----------|-----------|----------------|
| Rust gRPC | volo, grpcio | API breaking changes |
| Go gRPC | connectrpc, kitex | go.sum/genproto |
| Java gRPC | armeria, quarkus | Proto class naming |
| Kotlin gRPC | grpc-kotlin, spring, armeria | Gradle wrapper |
| GraalVM gRPC | quarkus, micronaut, grpc-java | Maven/native build |
| Dart gRPC | grpc-dart | Protobuf version |
| Rust GraphQL | async-graphql, juniper | Cargo deps |
| C# GraphQL | hotchocolate, graphql-dotnet | NuGet cycles |
| Dart GraphQL | graphql-server2, angel3, leto | shelf_router version |
| GraalVM GraphQL | smallrye, spring, micronaut | Maven/native |

**Ação**: Agente paralelo por categoria para corrigir e rebuildar

### 5.2 Implementações Missing (não implementadas)

| Ambiente | Framework | Status |
|----------|-----------|--------|
| C# REST | FastEndpoints | Build fail (NuGet) |
| Java GraphQL | SmallRye GraphQL | Não implementado |

---

## Fase 6 — Automação Completa

### 6.1 Script `run-all-benchmarks.sh`

Já criado. Precisa de:
- Pull no servidor
- Testar execução completa
- Ajustar parsing de resultados

### 6.2 Ansible Playbook `06-run-all-benchmarks.yml`

Já criado. Precisa de:
- Testar com `--ask-pass`
- Ajustar para single-node

### 6.3 Makefile Targets

```bash
make benchmark-all PROTOCOL=rest SCENARIO=health MODE=single-pod
make benchmark-all PROTOCOL=grpc SCENARIO=health MODE=single-pod
make benchmark-all PROTOCOL=graphql SCENARIO=health MODE=single-pod
```

---

## Cronograma Estimado

| Fase | Descrição | Tempo Estimado |
|------|-----------|---------------|
| 1 | Corrigir 11 pods Not Ready | 30 min |
| 2 | Benchmark isolado (32 impls × 5 cenários) | 4-6 horas |
| 3 | Coleta de métricas | (incluído na Fase 2) |
| 4 | Rankings normalizados | 30 min |
| 5 | Corrigir build fails restantes | 2-3 horas |
| 6 | Automação completa | 1 hora |
| **Total** | | **8-11 horas** |

---

## Prioridade de Execução

```
Fase 1 → Fase 2 (REST only) → Fase 4 (REST ranking) → Fase 2 (gRPC) → Fase 2 (GraphQL) → Fase 5 → Fase 6
```

**Justificativa**: Gerar resultados REST primeiro (mais implementações, mais dados), depois expandir para gRPC/GraphQL.

---

**Criado**: 2026-07-29
**Status**: PRONTO PARA EXECUÇÃO
