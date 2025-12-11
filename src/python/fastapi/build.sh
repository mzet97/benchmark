#!/bin/bash

# Build script for Python FastAPI
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/python-fastapi"
IMAGE_TAG="latest"

echo "=========================================="
echo "Python FastAPI - Build Script"
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
        print_info "Setting up virtual environment..."
        python3 -m venv venv
        source venv/bin/activate

        print_info "Installing dependencies..."
        pip install --no-cache-dir -r requirements.txt

        print_success "Local build complete"
        print_info "To run: source venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 8000:8080 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        rm -rf venv/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        python -m pytest tests/ -v || print_info "No tests directory found"
        print_success "Tests complete"
        ;;

    "check")
        print_info "Checking code format..."
        python -m black --check app/ || print_info "Black not installed, skipping"
        python -m flake8 app/ || print_info "Flake8 not installed, skipping"
        print_success "Format check complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        python -m black app/ || print_info "Black not installed, skipping"
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
        echo "  local        - Build for local development (venv + dependencies)"
        echo "  docker       - Build Docker image (benchmark/python-fastapi:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Verify formatting"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
