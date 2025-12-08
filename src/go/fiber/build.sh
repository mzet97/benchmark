#!/bin/bash

# Build script for Go Fiber
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/go-fiber"
IMAGE_TAG="latest"

echo "=========================================="
echo "Go Fiber - Build Script"
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

# Check if Go is installed
if ! command -v go &> /dev/null; then
    print_error "Go not found. Please install Go 1.23 or later."
    exit 1
fi

print_info "Go version: $(go version)"

# Set environment variables
export CGO_ENABLED=0

case $TARGET in
    "local")
        print_info "Building for local development..."
        go build -o ./bin/server ./cmd/server/main.go
        print_success "Build complete: ./bin/server"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 8080:8080 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        rm -rf ./bin/
        rm -rf ./vendor/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        go test -v ./...
        print_success "Tests complete"
        ;;

    "test-coverage")
        print_info "Running tests with coverage..."
        go test -v -coverprofile=coverage.out ./...
        go tool cover -html=coverage.out -o coverage.html
        print_success "Coverage report generated: coverage.html"
        ;;

    "vet")
        print_info "Running go vet..."
        go vet ./...
        print_success "Vet complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        go fmt ./...
        print_success "Format complete"
        ;;

    "mod-tidy")
        print_info "Tidying go modules..."
        go mod tidy
        print_success "Modules tidied"
        ;;

    "docker-push")
        print_info "Pushing Docker image..."
        docker push $IMAGE_NAME:$IMAGE_TAG
        print_success "Image pushed: $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "build-race")
        print_info "Building with race detector..."
        go build -race -o ./bin/server-race ./cmd/server/main.go
        print_success "Race detector build complete: ./bin/server-race"
        ;;

    "install-deps")
        print_info "Installing dependencies..."
        go mod download
        print_success "Dependencies installed"
        ;;

    *)
        echo "Usage: $0 {local|docker|clean|test|test-coverage|vet|fmt|mod-tidy|docker-push|build-race|install-deps}"
        echo ""
        echo "Targets:"
        echo "  local          - Build for local development"
        echo "  docker         - Build Docker image"
        echo "  clean          - Clean build artifacts"
        echo "  test           - Run tests"
        echo "  test-coverage  - Run tests with coverage"
        echo "  vet            - Run go vet"
        echo "  fmt            - Format code"
        echo "  mod-tidy       - Tidy go modules"
        echo "  docker-push    - Push Docker image to registry"
        echo "  build-race     - Build with race detector"
        echo "  install-deps   - Install dependencies"
        exit 1
        ;;
esac
