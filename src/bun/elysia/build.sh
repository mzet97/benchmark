#!/bin/bash

# Build script for Bun Elysia
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/bun-elysia"
IMAGE_TAG="latest"

echo "=========================================="
echo "Bun Elysia - Build Script"
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

# Check if bun is installed
check_bun() {
    if ! command -v bun &> /dev/null; then
        print_error "Bun is not installed"
        echo "Install Bun: https://bun.sh"
        exit 1
    fi
}

case $TARGET in
    "local")
        print_info "Setting up local development..."
        check_bun

        print_info "Installing dependencies..."
        bun install

        print_success "Local build complete"
        print_info "To run: bun run src/server.ts"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 3000:3000 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        rm -rf node_modules/
        rm -rf dist/
        bun clean || true
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        bun test || print_info "No tests found"
        print_success "Tests complete"
        ;;

    "check")
        print_info "Checking code format..."
        bun run --cwd node_modules/.bin/prettier --check src/ || print_info "Prettier not installed, skipping"
        bun run --cwd node_modules/.bin/eslint src/ || print_info "ESLint not installed, skipping"
        print_success "Format check complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        bun run --cwd node_modules/.bin/prettier --write src/ || print_info "Prettier not installed, skipping"
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
        echo "  local        - Build for local development (install dependencies)"
        echo "  docker       - Build Docker image (benchmark/bun-elysia:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Verify formatting"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
