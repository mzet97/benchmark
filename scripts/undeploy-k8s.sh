#!/bin/bash

# Script para remover deploy do Kubernetes
# Uso: ./scripts/undeploy-k8s.sh [namespace]

set -e

NAMESPACE=${1:-"benchmark"}

echo "=================================="
echo "Kubernetes Undeploy Script"
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

# Verificar se o namespace existe
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    print_warning "Namespace $NAMESPACE não existe. Nada para remover."
    exit 0
fi

print_info "Removendo recursos do namespace $NAMESPACE..."
echo ""

# Remover Service
print_info "Removendo Service..."
kubectl delete -f src/csharp/MinimalApi/k8s/service.yaml -n $NAMESPACE 2>/dev/null || print_warning "Service não encontrado"
print_success "Service removido (se existia)"
echo ""

# Remover Deployment
print_info "Removendo Deployment..."
kubectl delete -f src/csharp/MinimalApi/k8s/deployment.yaml -n $NAMESPACE 2>/dev/null || print_warning "Deployment não encontrado"
print_success "Deployment removido (se existia)"
echo ""

# Aguardar pods serem removidos
print_info "Aguardando pods serem removidos..."
sleep 5
kubectl get pods -n $NAMESPACE -l app=csharp-minimalapi 2>/dev/null || print_success "Pods removidos"
echo ""

# Remover ConfigMap
print_info "Removendo ConfigMap..."
kubectl delete -f src/csharp/MinimalApi/k8s/configmap.yaml -n $NAMESPACE 2>/dev/null || print_warning "ConfigMap não encontrado"
print_success "ConfigMap removido (se existia)"
echo ""

# Verificar se há outros recursos
print_info "Verificando recursos restantes..."
REMAINING=$(kubectl get all -n $NAMESPACE 2>/dev/null | grep -v "No resources found" | wc -l)

if [ "$REMAINING" -gt 0 ]; then
    print_warning "Recursos restantes encontrados:"
    kubectl get all -n $NAMESPACE
    echo ""
    print_info "Removendo recursos restantes..."
    kubectl delete all -n $NAMESPACE --all 2>/dev/null || true
fi

# Perguntar se quer remover o namespace
echo ""
read -p "Deseja remover o namespace $NAMESPACE também? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removendo namespace $NAMESPACE..."
    kubectl delete namespace $NAMESPACE
    print_success "Namespace $NAMESPACE removido"
else
    print_info "Namespace $NAMESPACE mantido"
fi

echo ""
echo "=================================="
echo "Undeploy Concluído!"
echo "=================================="
echo ""
print_success "Todos os recursos removidos do namespace $NAMESPACE"
