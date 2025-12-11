#!/bin/bash

# Build script for Dart Vaden
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/dart-vaden"
IMAGE_TAG="latest"

echo "=========================================="
echo "Dart Vaden - Build Script"
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

# Check if dart is installed
check_dart() {
    if ! command -v dart &> /dev/null; then
        print_error "Dart is not installed"
        echo "Install Dart: https://dart.dev"
        exit 1
    fi
}

case $TARGET in
    "local")
        print_info "Setting up local development..."
        check_dart

        print_info "Getting dependencies..."
        dart pub get

        print_info "Generating code..."
        dart run build_runner build --delete-conflicting-outputs || print_info "No build_runner needed"

        print_success "Local build complete"
        print_info "To run: dart run bin/server.dart"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 3000:3000 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        dart pub deps --delete-conflicting-outputs
        rm -rf .dart_tool/build/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        dart test
        print_success "Tests complete"
        ;;

    "check")
        print_info "Analyzing code..."
        dart analyze
        print_success "Analysis complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        dart format .
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
        echo "  local        - Build for local development (get deps + generate code)"
        echo "  docker       - Build Docker image (benchmark/dart-vaden:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Verify code analysis"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
