#!/bin/bash

# Script para remover deploy do Kubernetes
# Uso: ./scripts/undeploy-k8s.sh <language> [namespace]
# Exemplo: ./scripts/undeploy-k8s.sh csharp
#          ./scripts/undeploy-k8s.sh rust benchmark

set -e

# ================================
# Language -> Path/Label Mapping
# ================================
declare -A LANG_PATHS=(
    ["csharp"]="src/csharp/MinimalApi"
    ["rust"]="src/rust/actix-web"
    ["java"]="src/java/quarkus"
    ["go"]="src/go/fiber"
    ["kotlin"]="src/kotlin/ktor"
    ["nodejs"]="src/nodejs/fastify"
    ["python"]="src/python/fastapi"
    ["bun"]="src/bun/elysia"
    ["deno"]="src/deno/oak"
    ["dart"]="src/dart/vaden"
    ["graalvm"]="src/graalvm/vertx"
)

declare -A LANG_LABELS=(
    ["csharp"]="csharp-minimalapi"
    ["rust"]="rust-actix-web"
    ["java"]="java-quarkus"
    ["go"]="go-fiber"
    ["kotlin"]="kotlin-ktor"
    ["nodejs"]="nodejs-fastify"
    ["python"]="python-fastapi"
    ["bun"]="bun-elysia"
    ["deno"]="deno-oak"
    ["dart"]="dart-vaden"
    ["graalvm"]="graalvm-vertx"
)

# ================================
# Argument Parsing
# ================================
LANGUAGE=${1:-""}
NAMESPACE=${2:-"benchmark"}

if [ -z "$LANGUAGE" ]; then
    echo "Uso: $0 <language> [namespace]"
    echo ""
    echo "Linguagens disponíveis:"
    echo "  csharp, rust, java, go, kotlin, nodejs, python, bun, deno, dart, graalvm"
    echo ""
    echo "Exemplo:"
    echo "  $0 csharp"
    echo "  $0 rust benchmark"
    exit 1
fi

# Validate language
if [ -z "${LANG_PATHS[$LANGUAGE]}" ]; then
    echo "❌ Linguagem inválida: $LANGUAGE"
    echo "Linguagens disponíveis: ${!LANG_PATHS[@]}"
    exit 1
fi

MANIFEST_PATH="${LANG_PATHS[$LANGUAGE]}/k8s"
APP_LABEL="${LANG_LABELS[$LANGUAGE]}"

echo "=================================="
echo "Kubernetes Undeploy Script"
echo "=================================="
echo "Language:   $LANGUAGE"
echo "Namespace:  $NAMESPACE"
echo "Manifests:  $MANIFEST_PATH"
echo "App Label:  $APP_LABEL"
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info()    { echo -e "ℹ️  $1"; }

# ================================
# Pre-flight Checks
# ================================
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl não encontrado. Instale kubectl primeiro."
    exit 1
fi

# Verificar se o namespace existe
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    print_warning "Namespace $NAMESPACE não existe. Nada para remover."
    exit 0
fi

print_info "Removendo recursos de $LANGUAGE do namespace $NAMESPACE..."
echo ""

# ================================
# Remove Resources (reverse order)
# ================================

# Service
print_info "Removendo Service..."
kubectl delete -f ${MANIFEST_PATH}/service.yaml -n $NAMESPACE 2>/dev/null || print_warning "Service não encontrado"
print_success "Service removido (se existia)"
echo ""

# Deployment
print_info "Removendo Deployment..."
kubectl delete -f ${MANIFEST_PATH}/deployment.yaml -n $NAMESPACE 2>/dev/null || print_warning "Deployment não encontrado"
print_success "Deployment removido (se existia)"
echo ""

# Aguardar pods serem removidos
print_info "Aguardando pods serem removidos..."
sleep 5
kubectl get pods -n $NAMESPACE -l app=${APP_LABEL} 2>/dev/null || print_success "Pods removidos"
echo ""

# ConfigMap
print_info "Removendo ConfigMap..."
kubectl delete -f ${MANIFEST_PATH}/configmap.yaml -n $NAMESPACE 2>/dev/null || print_warning "ConfigMap não encontrado"
print_success "ConfigMap removido (se existia)"
echo ""

# ================================
# Verificar recursos restantes
# ================================
print_info "Verificando recursos restantes no namespace..."
REMAINING=$(kubectl get all -n $NAMESPACE 2>/dev/null | grep -v "No resources found" | grep -c -v "^NAME" || true)

if [ "$REMAINING" -gt 0 ]; then
    print_warning "Recursos restantes encontrados no namespace $NAMESPACE:"
    kubectl get all -n $NAMESPACE
    echo ""
    print_info "Estes recursos pertencem a outras linguagens e foram mantidos."
else
    print_success "Nenhum recurso restante no namespace"
fi

# ================================
# Perguntar sobre namespace
# ================================
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
print_success "Recursos de $LANGUAGE removidos do namespace $NAMESPACE"
