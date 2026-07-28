#!/bin/bash

# Script automatizado para deploy no Kubernetes
# Uso: ./scripts/deploy-k8s.sh <language> [namespace]
# Exemplo: ./scripts/deploy-k8s.sh csharp
#          ./scripts/deploy-k8s.sh rust benchmark

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

declare -A LANG_PORTS=(
    ["csharp"]="8080"
    ["rust"]="8080"
    ["java"]="8080"
    ["go"]="3000"
    ["kotlin"]="3000"
    ["nodejs"]="3000"
    ["python"]="8000"
    ["bun"]="3000"
    ["deno"]="3000"
    ["dart"]="3000"
    ["graalvm"]="3000"
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
APP_PORT="${LANG_PORTS[$LANGUAGE]}"

echo "=================================="
echo "Kubernetes Deploy Script"
echo "=================================="
echo "Language:   $LANGUAGE"
echo "Namespace:  $NAMESPACE"
echo "Manifests:  $MANIFEST_PATH"
echo "App Label:  $APP_LABEL"
echo "Port:       $APP_PORT"
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
    print_warning "  PostgreSQL inacessível — o deploy continuará, mas a aplicação pode falhar"
fi

print_info "  - Testando Redis (redis.home.arpa:30379)..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/redis.home.arpa/30379" 2>/dev/null; then
    print_success "  Redis acessível"
else
    print_warning "  Redis inacessível — o deploy continuará, mas a aplicação pode falhar"
fi
echo ""

# ================================
# Apply Secrets
# ================================
print_info "Aplicando Secrets..."
kubectl apply -f kubernetes/secrets.yaml -n $NAMESPACE 2>/dev/null || print_warning "Secrets já aplicados ou arquivo não encontrado"
echo ""

# ================================
# Deploy Resources
# ================================
# ConfigMap
print_info "Aplicando ConfigMap..."
kubectl apply -f ${MANIFEST_PATH}/configmap.yaml -n $NAMESPACE
print_success "ConfigMap aplicado"
echo ""

# Deployment
print_info "Aplicando Deployment..."
kubectl apply -f ${MANIFEST_PATH}/deployment.yaml -n $NAMESPACE
print_success "Deployment aplicado"
echo ""

# Aguardar pods
print_info "Aguardando pods ficarem prontos (timeout: 120s)..."
if kubectl wait --for=condition=ready pod -l app=${APP_LABEL} --timeout=120s -n $NAMESPACE 2>/dev/null; then
    print_success "Pods estão prontos"
else
    print_warning "Timeout aguardando pods. Verificando status..."
    kubectl get pods -n $NAMESPACE -l app=${APP_LABEL}
fi
echo ""

# Service
print_info "Aplicando Service..."
kubectl apply -f ${MANIFEST_PATH}/service.yaml -n $NAMESPACE
print_success "Service aplicado"
echo ""

# ================================
# Status Final
# ================================
print_info "Status final dos recursos:"
echo ""
kubectl get all -n $NAMESPACE -l app=${APP_LABEL}
echo ""

print_info "Detalhes dos pods:"
kubectl get pods -n $NAMESPACE -l app=${APP_LABEL} -o wide
echo ""

# Health check
print_info "Executando teste de saúde..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=${APP_LABEL} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POD_NAME" ]; then
    print_info "Testando endpoint /health no pod $POD_NAME..."
    if kubectl exec -n $NAMESPACE $POD_NAME -- wget -q -O- http://localhost:${APP_PORT}/health > /dev/null 2>&1 || \
       kubectl exec -n $NAMESPACE $POD_NAME -- curl -s http://localhost:${APP_PORT}/health > /dev/null 2>&1; then
        print_success "Health check OK"
    else
        print_warning "Health check falhou (ainda pode estar inicializando)"
    fi
else
    print_error "Nenhum pod encontrado"
fi
echo ""

# ================================
# Instruções Finais
# ================================
echo "=================================="
echo "Deploy Concluído!"
echo "=================================="
echo ""
print_success "Recursos aplicados:"
echo "  - Namespace:  $NAMESPACE"
echo "  - Language:   $LANGUAGE"
echo "  - App Label:  $APP_LABEL"
echo "  - ConfigMap:  ${APP_LABEL}-config"
echo "  - Deployment: ${APP_LABEL}"
echo "  - Service:    ${APP_LABEL}"
echo ""
print_info "Para testar a aplicação:"
echo "  1. Port-forward: kubectl port-forward -n $NAMESPACE svc/${APP_LABEL} ${APP_PORT}:80"
echo "  2. Testar: curl http://localhost:${APP_PORT}/health"
echo ""
print_info "Para ver logs:"
echo "  kubectl logs -f -n $NAMESPACE -l app=${APP_LABEL}"
echo ""
print_info "Para fazer benchmark:"
echo "  ./scripts/benchmark-wrk-${LANGUAGE}.sh"
echo ""
print_info "Para remover:"
echo "  ./scripts/undeploy-k8s.sh $LANGUAGE $NAMESPACE"
echo ""
print_success "Deploy finalizado com sucesso!"
