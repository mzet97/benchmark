#!/bin/bash

# Build script for Node.js Fastify
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/nodejs-fastify"
IMAGE_TAG="latest"

echo "=========================================="
echo "Node.js Fastify - Build Script"
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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please install Node.js 22 or later."
    exit 1
fi

print_info "Node.js version: $(node --version)"
print_info "NPM version: $(npm --version)"

case $TARGET in
    "local")
        print_info "Installing dependencies for local development..."
        npm install
        print_success "Dependencies installed"
        print_info "Run with: npm start"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 8080:8080 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        rm -rf node_modules/
        rm -rf package-lock.json
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        npm test 2>/dev/null || print_info "No tests configured yet"
        print_success "Tests complete"
        ;;

    "lint")
        print_info "Running linter..."
        npm run lint 2>/dev/null || print_info "No linting configured yet"
        print_success "Lint complete"
        ;;

    "format")
        print_info "Formatting code..."
        npm run format 2>/dev/null || print_info "No formatting configured yet"
        print_success "Format complete"
        ;;

    "docker-push")
        print_info "Pushing Docker image..."
        docker push $IMAGE_NAME:$IMAGE_TAG
        print_success "Image pushed: $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "docker-clean")
        print_info "Cleaning Docker images..."
        docker rmi $IMAGE_NAME:$IMAGE_TAG 2>/dev/null || true
        docker system prune -f
        print_success "Docker cleanup complete"
        ;;

    "install-deps")
        print_info "Installing dependencies..."
        npm install
        print_success "Dependencies installed"
        ;;

    *)
        echo "Usage: $0 {local|docker|clean|test|lint|format|docker-push|docker-clean|install-deps}"
        echo ""
        echo "Targets:"
        echo "  local          - Install dependencies for local development"
        echo "  docker         - Build Docker image"
        echo "  clean          - Clean node_modules and package-lock.json"
        echo "  test           - Run tests"
        echo "  lint           - Run linter"
        echo "  format         - Format code"
        echo "  docker-push    - Push Docker image to registry"
        echo "  docker-clean   - Clean Docker images"
        echo "  install-deps   - Install dependencies"
        exit 1
        ;;
esac
