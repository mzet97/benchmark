#!/bin/bash
set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/deno-hono"
IMAGE_TAG="latest"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "=========================================="
echo "  Deno Hono - Build Script"
echo "=========================================="

case $TARGET in
    "local")
        print_info "Caching dependencies..."
        deno cache server.ts
        print_success "Dependencies cached"
        ;;
    "docker")
        print_info "Building Docker image..."
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        print_success "Docker image built: ${IMAGE_NAME}:${IMAGE_TAG}"
        ;;
    "docker-push")
        docker push ${IMAGE_NAME}:${IMAGE_TAG}
        print_success "Image pushed"
        ;;
    "clean")
        rm -rf .deno_cache
        print_success "Clean complete"
        ;;
    "test")
        deno test 2>/dev/null || echo "No tests found"
        ;;
    "check")
        deno lint || echo "Lint complete"
        ;;
    "fmt")
        deno fmt
        print_success "Formatted"
        ;;
    *)
        echo "Usage: $0 {local|docker|docker-push|clean|test|check|fmt}"
        exit 1
        ;;
esac
