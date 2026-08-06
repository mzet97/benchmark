# 🚀 Quick Reference - Kubernetes Deploy

## ⚡ Deploy Rápido (1 comando)

```bash
./scripts/deploy-k8s.sh benchmark
```

## 🧹 Undeploy

```bash
./scripts/undeploy-k8s.sh benchmark
```

## 📋 Deploy Manual (Passo a Passo)

```bash
# 1. Criar namespace
kubectl create namespace benchmark

# 2. Aplicar manifestos
kubectl apply -f src/csharp/MinimalApi/k8s/configmap.yaml -n benchmark
kubectl apply -f src/csharp/MinimalApi/k8s/deployment.yaml -n benchmark
kubectl apply -f src/csharp/MinimalApi/k8s/service.yaml -n benchmark

# 3. Aguardar pods
kubectl wait --for=condition=ready pod -l app=csharp-minimalapi --timeout=120s -n benchmark

# 4. Verificar
kubectl get all -n benchmark -l app=csharp-minimalapi
```

## 🔍 Verificar Status

```bash
# Todos os recursos
kubectl get all -n benchmark -l app=csharp-minimalapi

# Apenas pods
kubectl get pods -n benchmark -o wide

# Logs
kubectl logs -f -n benchmark -l app=csharp-minimalapi

# Eventos
kubectl get events -n benchmark --sort-by='.lastTimestamp'
```

## 🧪 Testar Aplicação

### Port-Forward (Teste Local)
```bash
kubectl port-forward -n benchmark svc/csharp-minimalapi 8080:80
```

### Test Inside Cluster
```bash
kubectl run -it --rm test --image=curlimages/curl:latest --restart=Never -- sh
# Dentro do pod:
curl http://csharp-minimalapi.benchmark.svc.cluster.local/health
exit
```

## ⚖️ Scale

```bash
# Aumentar réplicas
kubectl scale deployment csharp-minimalapi --replicas=10 -n benchmark

# Verificar
kubectl get pods -n benchmark -l app=csharp-minimalapi
```

## 🔧 Debug

```bash
# Ver logs de um pod específico
POD=$(kubectl get pods -n benchmark -l app=csharp-minimalapi -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n benchmark $POD

# Ver detalhes do pod
kubectl describe pod -n benchmark $POD

# Executar comando no pod
kubectl exec -it -n benchmark $POD -- sh
```

## ❌ Remover Manual

```bash
kubectl delete -f src/csharp/MinimalApi/k8s/service.yaml -n benchmark
kubectl delete -f src/csharp/MinimalApi/k8s/deployment.yaml -n benchmark
kubectl delete -f src/csharp/MinimalApi/k8s/configmap.yaml -n benchmark
kubectl delete namespace benchmark
```

## 📊 Endpoints Test

```bash
curl http://localhost:8080/health
curl http://localhost:8080/json
curl "http://localhost:8080/db/simple?id=1"
curl "http://localhost:8080/db/complex?days=30"
curl "http://localhost:8080/cache?key=test"
```

## 🔗 URLs

- **Local**: http://localhost:8080 (via port-forward)
- **Cluster**: http://csharp-minimalapi.benchmark.svc.cluster.local

## 📖 Documentação Completa

Veja [KUBERNETES_TUTORIAL.md](KUBERNETES_TUTORIAL.md) para tutorial completo.

---

**Status**: ✅ Pronto para deploy
