#!/bin/bash

# Build script for Rust Axum
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/rust-axum"
IMAGE_TAG="latest"

echo "=========================================="
echo "Rust Axum - Build Script"
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

case $TARGET in
    "local")
        print_info "Building for local development..."
        cargo build --release
        print_success "Build complete: ./target/release/benchmark-axum"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 3000:3000 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        cargo clean
        rm -rf target/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        cargo test
        print_success "Tests complete"
        ;;

    "check")
        print_info "Running clippy..."
        rustup component add clippy 2>/dev/null || true
        cargo clippy --all-targets --all-features -- -D warnings
        print_success "Clippy complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        rustup component add rustfmt 2>/dev/null || true
        cargo fmt --all
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
        echo "  local        - Build for local development (./target/release/benchmark-axum)"
        echo "  docker       - Build Docker image (benchmark/rust-axum:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Run clippy lints"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
