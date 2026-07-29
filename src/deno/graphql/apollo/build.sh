#!/bin/bash
set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/deno-graphql-apollo"
IMAGE_TAG="latest"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[OK] $1${NC}"; }
print_error()   { echo -e "${RED}[ERROR] $1${NC}"; }
print_info()    { echo -e "${YELLOW}[INFO] $1${NC}"; }

echo "=========================================="
echo "  Deno GraphQL Apollo - Build Script"
echo "=========================================="
echo "Target: $TARGET"
echo ""

case $TARGET in
    "local")
        print_info "Caching dependencies..."
        deno cache server.ts
        print_success "Dependencies cached"
        print_info "To run: deno run --allow-net --allow-env --allow-read server.ts"
        ;;
    "docker")
        print_info "Building Docker image..."
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        print_success "Docker image created: ${IMAGE_NAME}:${IMAGE_TAG}"
        ;;
    "docker-push")
        docker push ${IMAGE_NAME}:${IMAGE_TAG}
        print_success "Image pushed: ${IMAGE_NAME}:${IMAGE_TAG}"
        ;;
    "clean")
        rm -rf .deno_cache
        print_success "Clean complete"
        ;;
    *)
        echo "Usage: $0 {local|docker|docker-push|clean}"
        echo ""
        echo "Targets:"
        echo "  local        - Cache dependencies for local development"
        echo "  docker       - Build Docker image"
        echo "  docker-push  - Push Docker image to registry"
        echo "  clean        - Clean artifacts"
        exit 1
        ;;
esac
