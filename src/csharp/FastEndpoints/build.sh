#!/bin/bash

# Build script for C# .NET 9 FastEndpoints API
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/csharp-rest-fastendpoints"
IMAGE_TAG="latest"

echo "=========================================="
echo "C# .NET 9 FastEndpoints API - Build Script"
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
    echo -e "${GREEN}[OK] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

case $TARGET in
    "local")
        print_info "Building for local development..."
        dotnet build -c Release
        print_success "Build complete: ./bin/Release/net9.0/FastEndpoints"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 8080:8080 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        dotnet clean
        rm -rf bin/ obj/ publish/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        dotnet test --no-build
        print_success "Tests complete"
        ;;

    "check")
        print_info "Running dotnet format..."
        dotnet format --verify-no-changes --verbosity minimal
        print_success "Format check complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        dotnet format --write Verified
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
        echo "  local        - Build for local development"
        echo "  docker       - Build Docker image ($IMAGE_NAME:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Verify formatting"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
