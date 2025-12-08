#!/bin/bash

# Script automatizado para deploy no Kubernetes
# Uso: ./scripts/deploy-k8s.sh [namespace]

set -e

NAMESPACE=${1:-"benchmark"}

echo "=================================="
echo "Kubernetes Deploy Script"
echo "=================================="
echo "Namespace: $NAMESPACE"
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir colorido
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl não encontrado. Instale kubectl primeiro."
    exit 1
fi

# Verificar conexão com o cluster
print_info "Verificando conexão com o cluster..."
if kubectl cluster-info &> /dev/null; then
    print_success "Conectado ao cluster Kubernetes"
    kubectl cluster-info | head -1
else
    print_error "Não foi possível conectar ao cluster"
    exit 1
fi
echo ""

# Verificar nós
print_info "Verificando nós disponíveis..."
kubectl get nodes
echo ""

# Criar namespace se não existir
print_info "Criando namespace $NAMESPACE..."
if kubectl get namespace $NAMESPACE &> /dev/null; then
    print_warning "Namespace $NAMESPACE já existe"
else
    kubectl create namespace $NAMESPACE
    print_success "Namespace $NAMESPACE criado"
fi
echo ""

# Verificar conectividade com databases
print_info "Verificando conectividade com databases..."

print_info "  - Testando PostgreSQL (spsql.home.arpa:5432)..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/spsql.home.arpa/5432" 2>/dev/null; then
    print_success "  PostgreSQL acessível"
else
    print_error "  PostgreSQL inacessível"
    print_warning "  O deploy continuará, mas a aplicação pode falhar"
fi

print_info "  - Testando Redis (redis.home.arpa:30379)..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/redis.home.arpa/30379" 2>/dev/null; then
    print_success "  Redis acessível"
else
    print_error "  Redis inacessível"
    print_warning "  O deploy continuará, mas a aplicação pode falhar"
fi
echo ""

# Deploy ConfigMap
print_info "Aplicando ConfigMap..."
kubectl apply -f src/csharp/MinimalApi/k8s/configmap.yaml -n $NAMESPACE
if [ $? -eq 0 ]; then
    print_success "ConfigMap aplicado"
else
    print_error "Falha ao aplicar ConfigMap"
    exit 1
fi
echo ""

# Deploy Deployment
print_info "Aplicando Deployment..."
kubectl apply -f src/csharp/MinimalApi/k8s/deployment.yaml -n $NAMESPACE
if [ $? -eq 0 ]; then
    print_success "Deployment aplicado"
else
    print_error "Falha ao aplicar Deployment"
    exit 1
fi
echo ""

# Aguardar pods
print_info "Aguardando pods ficarem prontos (timeout: 120s)..."
if kubectl wait --for=condition=ready pod -l app=csharp-minimalapi --timeout=120s -n $NAMESPACE 2>/dev/null; then
    print_success "Pods estão prontos"
else
    print_warning "Timeout aguardando pods. Verificando status..."
    kubectl get pods -n $NAMESPACE -l app=csharp-minimalapi
fi
echo ""

# Deploy Service
print_info "Aplicando Service..."
kubectl apply -f src/csharp/MinimalApi/k8s/service.yaml -n $NAMESPACE
if [ $? -eq 0 ]; then
    print_success "Service aplicado"
else
    print_error "Falha ao aplicar Service"
    exit 1
fi
echo ""

# Verificar status final
print_info "Status final dos recursos:"
echo ""
kubectl get all -n $NAMESPACE -l app=csharp-minimalapi
echo ""

# Verificar pods em detalhes
print_info "Detalhes dos pods:"
kubectl get pods -n $NAMESPACE -l app=csharp-minimalapi -o wide
echo ""

# Executar teste de saúde
print_info "Executando teste de saúde..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=csharp-minimalapi -o jsonpath='{.items[0].metadata.name}')

if [ -n "$POD_NAME" ]; then
    print_info "Testando endpoint /health no pod $POD_NAME..."
    if kubectl exec -n $NAMESPACE $POD_NAME -- curl -s http://localhost:8080/health > /dev/null 2>&1; then
        print_success "Health check OK"
    else
        print_warning "Health check falhou (ainda pode estar inicializando)"
    fi
else
    print_error "Nenhum pod encontrado"
fi
echo ""

# Instruções finais
echo "=================================="
echo "Deploy Concluído!"
echo "=================================="
echo ""
print_success "Recursos aplicados:"
echo "  - Namespace: $NAMESPACE"
echo "  - ConfigMap: csharp-minimalapi-config"
echo "  - Deployment: csharp-minimalapi"
echo "  - Service: csharp-minimalapi"
echo ""
print_info "Para testar a aplicação:"
echo "  1. Port-forward: kubectl port-forward -n $NAMESPACE svc/csharp-minimalapi 8080:80"
echo "  2. Testar: curl http://localhost:8080/health"
echo ""
print_info "Para ver logs:"
echo "  kubectl logs -f -n $NAMESPACE -l app=csharp-minimalapi"
echo ""
print_info "Para fazer benchmark:"
echo "  ./scripts/benchmark-wrk.sh csharp-minimalapi"
echo ""
print_info "Para remover:"
echo "  ./scripts/undeploy-k8s.sh $NAMESPACE"
echo ""
print_success "Deploy finalizado com sucesso!"
