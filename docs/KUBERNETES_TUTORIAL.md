# Tutorial Kubernetes - Deploy C# Benchmark API

## 📋 Pré-requisitos

### Ferramentas Necessárias
- [ ] `kubectl` instalado e configurado
- [ ] Acesso ao cluster Kubernetes
- [ ] Docker (para build da imagem)
- [ ] Conta com permissões para criar recursos no cluster

### Verificar Acesso
```bash
# Verificar conexão com o cluster
kubectl cluster-info

# Verificar nós
kubectl get nodes

# Verificar contexto atual
kubectl config current-context
```

---

## 🚀 Passo a Passo - Deploy Completo

### Passo 1: Build da Imagem Docker

```bash
# Navegar para o diretório
cd src/csharp/MinimalApi

# Build da imagem (pode demorar 2-3 minutos)
docker build -t benchmark/csharp-minimalapi:latest .

# Verificar imagem criada
docker images | grep benchmark/csharp-minimalapi

# (Opcional) Push para registry
# docker push benchmark/csharp-minimalapi:latest
```

**⚠️ Observação**: Se não tiver Docker, pode pular este passo e usar imagem existente.

---

### Passo 2: Preparar o Cluster

#### 2.1 Criar Namespace
```bash
# Criar namespace dedicado
kubectl create namespace benchmark

# Verificar namespace
kubectl get namespaces
```

#### 2.2 Verificar Conectividade com Databases

**Testar PostgreSQL:**
```bash
# Testar conexão TCP
timeout 5 bash -c "cat < /dev/null > /dev/tcp/spsql.home.arpa/5432" && echo "✅ PostgreSQL acessível" || echo "❌ PostgreSQL inacessível"
```

**Testar Redis:**
```bash
# Testar conexão TCP
timeout 5 bash -c "cat < /dev/null > /dev/tcp/redis.home.arpa/30379" && echo "✅ Redis acessível" || echo "❌ Redis inacessível"
```

**⚠️ Se os databases não estiverem acessíveis:**
- Verificar se os IPs estão corretos
- Verificar se há conectividade de rede
- Verificar firewall/segurança

---

### Passo 3: Deploy da Aplicação

#### 3.1 Aplicar ConfigMap
```bash
# Aplicar ConfigMap com configurações
kubectl apply -f src/csharp/MinimalApi/k8s/configmap.yaml -n benchmark

# Verificar
kubectl get configmap -n benchmark
kubectl describe configmap csharp-minimalapi-config -n benchmark
```

#### 3.2 Aplicar Deployment
```bash
# Aplicar Deployment
kubectl apply -f src/csharp/MinimalApi/k8s/deployment.yaml -n benchmark

# Verificar status
kubectl get deployment -n benchmark
kubectl describe deployment csharp-minimalapi -n benchmark
```

#### 3.3 Verificar Pods
```bash
# Listar pods
kubectl get pods -n benchmark -l app=csharp-minimalapi

# Ver detalhes do pod
kubectl describe pod -n benchmark -l app=csharp-minimalapi

# Ver logs em tempo real
kubectl logs -f -n benchmark -l app=csharp-minimalapi
```

#### 3.4 Aguardar Pods Prontos
```bash
# Aguardar todos os pods ficarem prontos (timeout 2 minutos)
kubectl wait --for=condition=ready pod -l app=csharp-minimalapi --timeout=120s -n benchmark

# Se der erro, verificar o que está acontecendo
kubectl get events -n benchmark --sort-by='.lastTimestamp'
```

---

### Passo 4: Expor o Serviço

#### 4.1 Aplicar Service
```bash
# Aplicar Service
kubectl apply -f src/csharp/MinimalApi/k8s/service.yaml -n benchmark

# Verificar Services
kubectl get svc -n benchmark
kubectl get svc -n benchmark -l app=csharp-minimalapi

# Ver detalhes
kubectl describe svc csharp-minimalapi -n benchmark
```

#### 4.2 Verificar Service
```bash
# O service deve estar com ClusterIP
kubectl get svc csharp-minimalapi -n benchmark -o wide
```

---

### Passo 5: Testar a Aplicação

#### 5.1 Port-Forward (Teste Local)
```bash
# Abrir túnel para teste local
kubectl port-forward -n benchmark svc/csharp-minimalapi 8080:80

# Em outro terminal, testar:
curl http://localhost:8080/health
curl http://localhost:8080/json
curl "http://localhost:8080/db/simple?id=1"
curl "http://localhost:8080/db/complex?days=30"
curl "http://localhost:8080/cache?key=test"
```

#### 5.2 Teste Inside Cluster (Create Debug Pod)
```bash
# Criar pod temporário para teste
kubectl run -it --rm debug --image=curlimages/curl:latest --restart=Never -- sh

# Dentro do pod:
curl http://csharp-minimalapi.benchmark.svc.cluster.local/health
curl http://csharp-minimalapi.benchmark.svc.cluster.local/json
curl "http://csharp-minimalapi.benchmark.svc.cluster.local/db/simple?id=1"

# Sair
exit
```

---

### Passo 6: Verificar Status Completo

#### 6.1 Verificar Todos os Recursos
```bash
# Ver todos os recursos do namespace
kubectl get all -n benchmark -l app=csharp-minimalapi

# Verificar pod status
kubectl get pods -n benchmark -o wide

# Verificar eventos
kubectl get events -n benchmark --sort-by='.lastTimestamp' | head -20

# Ver logs dos pods
kubectl logs -n benchmark -l app=csharp-minimalapi --tail=50
```

#### 6.2 Verificar Resource Usage
```bash
# Se métricas-server estiver instalado
kubectl top pods -n benchmark -l app=csharp-minimalapi

# Ver limits e requests
kubectl describe deployment csharp-minimalapi -n benchmark | grep -A 10 "Limits\|Requests"
```

---

### Passo 7: Executar Benchmarks

#### 7.1 Preparar Ambiente de Teste
```bash
# Em uma nova sessão, criar pod de benchmark
kubectl run -it --rm benchmark --image=alpine/wget:latest --restart=Never -- sh

# Instalar ferramentas
apk add --no-cache curl wrk

# Testar conectividade
curl -v http://csharp-minimalapi.benchmark.svc.cluster.local/health

# Sair
exit
```

#### 7.2 Executar wrk Benchmark
```bash
# Executar benchmark wrk
kubectl run -it --rm benchmark-wrk --image=alpine/wrk:latest --restart=Never -- sh

# No pod:
wrk -t4 -c100 -d30s --latency http://csharp-minimalapi.benchmark.svc.cluster.local/health

# Testar outros endpoints
wrk -t4 -c100 -d30s --latency http://csharp-minimalapi.benchmark.svc.cluster.local/json
wrk -t4 -c100 -d30s --latency "http://csharp-minimalapi.benchmark.svc.cluster.local/db/simple?id=1"

# Sair
exit
```

---

### Passo 8: Scaling (Teste de Escala)

#### 8.1 Scale Up
```bash
# Aumentar para 10 réplicas
kubectl scale deployment csharp-minimalapi --replicas=10 -n benchmark

# Verificar
kubectl get pods -n benchmark -l app=csharp-minimalapi
kubectl get deployment csharp-minimalapi -n benchmark
```

#### 8.2 Verificar Load Balancing
```bash
# Verificar se os pods estão distribuidos
kubectl get pods -n benchmark -o wide | grep csharp-minimalapi

# Testar se o service está load balancing
for i in {1..10}; do
  curl -s http://csharp-minimalapi.benchmark.svc.cluster.local/health | jq .
done
```

#### 8.3 Scale Down
```bash
# Voltar para 5 réplicas
kubectl scale deployment csharp-minimalapi --replicas=5 -n benchmark

# Verificar
kubectl get pods -n benchmark -l app=csharp-minimalapi
```

---

## 🔧 Comandos de Diagnóstico

### Logs e Debug
```bash
# Ver logs em tempo real
kubectl logs -f -n benchmark -l app=csharp-minimalapi

# Ver logs de um pod específico
POD_NAME=$(kubectl get pods -n benchmark -l app=csharp-minimalapi -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n benchmark $POD_NAME

# Ver eventos
kubectl get events -n benchmark --sort-by='.lastTimestamp'

# Descrever pod
kubectl describe pod -n benchmark -l app=csharp-minimalapi
```

### Conectividade
```bash
# Testar DNS interno
kubectl run -it --rm nslookup --image=busybox --restart=Never -- nslookup csharp-minimalapi.benchmark.svc.cluster.local

# Testar conectividade com database
kubectl run -it --rm debug --image=curlimages/curl:latest --restart=Never -- sh
# Dentro do pod:
nc -zv spsql.home.arpa 5432
nc -zv redis.home.arpa 30379
exit
```

### Resource Monitoring
```bash
# Ver uso de recursos
kubectl top pods -n benchmark -l app=csharp-minimalapi

# Ver describir deployment
kubectl describe deployment csharp-minimalapi -n benchmark
```

---

## 🧹 Limpeza (Undeploy)

### Remover Recursos
```bash
# Remover todos os recursos
kubectl delete -f src/csharp/MinimalApi/k8s/service.yaml -n benchmark
kubectl delete -f src/csharp/MinimalApi/k8s/deployment.yaml -n benchmark
kubectl delete -f src/csharp/MinimalApi/k8s/configmap.yaml -n benchmark

# Remover namespace (opcional)
kubectl delete namespace benchmark

# Verificar se tudo foi removido
kubectl get all -n benchmark 2>/dev/null || echo "✅ Namespace removido"
```

---

## ⚠️ Troubleshooting

### Problema: Pods não iniciam
```bash
# Verificar logs
kubectl logs -n benchmark -l app=csharp-minimalapi

# Verificar eventos
kubectl get events -n benchmark --sort-by='.lastTimestamp'

# Verificar se a imagem existe
kubectl describe pod -n benchmark <pod-name> | grep "Failed to pull image"

# Verificar se as variáveis de ambiente estão corretas
kubectl exec -it -n benchmark <pod-name> -- env | grep -E "DATABASE|REDIS"
```

### Problema: Erro de Conexão com Database
```bash
# Testar conectividade
kubectl run -it --rm debug --image=curlimages/curl:latest --restart=Never -- sh
# Dentro do pod:
nc -zv spsql.home.arpa 5432
# Se falhar, verificar rede/firewall

# Verificar string de conexão no pod
kubectl exec -it -n benchmark <pod-name> -- env | grep DATABASE
```

### Problema: Service não acessível
```bash
# Verificar se o service existe
kubectl get svc -n benchmark

# Verificar se o service tem endpoints
kubectl get endpoints -n benchmark

# Verificar selectors
kubectl get svc csharp-minimalapi -n benchmark -o yaml | grep selector
kubectl get pods -n benchmark -l app=csharp-minimalapi --show-labels
```

### Problema: Alto uso de memória/CPU
```bash
# Verificar uso
kubectl top pods -n benchmark -l app=csharp-minimalapi

# Se necessário, aumentar limits
kubectl patch deployment csharp-minimalapi -n benchmark -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","resources":{"limits":{"memory":"1Gi"}}}]}}}}'

# Verificar se há memory leaks nos logs
kubectl logs -n benchmark -l app=csharp-minimalapi | grep -i "memory\|oom"
```

---

## 📊 Status Final

### Checklist de Verificação
- [ ] Namespace `benchmark` criado
- [ ] ConfigMap aplicado
- [ ] Deployment com 5 réplicas rodando
- [ ] Service criado e acessível
- [ ] Todos os pods em estado `Running`
- [ ] Health check respondendo
- [ ] Todos os 5 endpoints funcionando
- [ ] Logs sem erros críticos
- [ ] Benchmarks executados com sucesso

### Informações do Deploy
```bash
# Resumo do deploy
kubectl get all -n benchmark -l app=csharp-minimalapi

# Status dos pods
kubectl get pods -n benchmark -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.containerStatuses[0].ready}{"\n"}{end}'

# Resource usage
kubectl top pods -n benchmark -l app=csharp-minimalapi
```

---

## 🎯 Próximos Passos

Após o deploy bem-sucedido:

1. **Executar Benchmarks Completos**
   ```bash
   # wrk
   ./scripts/benchmark-wrk.sh csharp-minimalapi

   # k6
   ./scripts/benchmark-k6.sh csharp-minimalapi
   ```

2. **Coletar Métricas**
   ```bash
   ./scripts/collect-metrics.sh
   ```

3. **Próxima Linguagem**
   - Implementar Rust (Actix Web)
   - Seguir mesmo processo

---

## 📚 Referências

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [.NET Native AOT](https://learn.microsoft.com/dotnet/core/deploying/native-aot/)
- [Health Checks in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

**Última Atualização**: 2025-12-07
**Versão**: 1.0
