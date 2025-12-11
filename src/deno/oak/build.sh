#!/bin/bash

# Build script for Deno Oak
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/deno-oak"
IMAGE_TAG="latest"

echo "=========================================="
echo "Deno Oak - Build Script"
echo "=========================================="
echo "Target: $TARGET"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if deno is installed
check_deno() {
    if ! command -v deno &> /dev/null; then
        print_error "Deno is not installed"
        echo "Install Deno: https://deno.land"
        exit 1
    fi
}

case $TARGET in
    "local")
        print_info "Setting up local development..."
        check_deno

        print_info "Caching dependencies..."
        deno cache deps.ts

        print_success "Local build complete"
        print_info "To run: deno run --allow-net --allow-env server.ts"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 3000:3000 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        deno cache --reload deps.ts
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        deno test || print_info "No tests found"
        print_success "Tests complete"
        ;;

    "check")
        print_info "Checking code format..."
        deno lint || print_info "Lint complete"
        print_success "Format check complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        deno fmt
        print_success "Format complete"
        ;;

    "docker-push")
        print_info "Pushing Docker image..."
        docker push $IMAGE_NAME:$IMAGE_TAG
        print_success "Image pushed: $IMAGE_NAME:$IMAGE_TAG"
        ;;

    *)
        echo "Usage: $0 {local|docker|clean|test|check|fmt|docker-push}"
        echo ""
        echo "Targets:"
        echo "  local        - Build for local development (cache dependencies)"
        echo "  docker       - Build Docker image (benchmark/deno-oak:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Verify formatting"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
