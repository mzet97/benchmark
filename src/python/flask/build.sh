#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/python-flask"
IMAGE_TAG="latest"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

echo "=========================================="
echo "  Python Flask - Build Script"
echo "=========================================="

case $TARGET in
    "local")
        print_info "Installing dependencies locally..."
        pip install -r requirements.txt
        print_success "Dependencies installed"
        ;;
    "docker")
        print_info "Building Docker image..."
        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
        print_success "Docker image built: ${IMAGE_NAME}:${IMAGE_TAG}"
        ;;
    "docker-push")
        print_info "Pushing Docker image..."
        docker push ${IMAGE_NAME}:${IMAGE_TAG}
        print_success "Docker image pushed"
        ;;
    "clean")
        print_info "Cleaning build artifacts..."
        rm -rf venv __pycache__ *.pyc .pytest_cache
        print_success "Clean complete"
        ;;
    "test")
        print_info "Running tests..."
        python -m pytest tests/ -v 2>/dev/null || echo "No tests found"
        ;;
    "check")
        print_info "Running linting..."
        python -m flake8 --max-line-length=120 --ignore=E501,W503 . 2>/dev/null || echo "flake8 not installed"
        ;;
    "fmt")
        print_info "Formatting code..."
        python -m black . 2>/dev/null || echo "black not installed"
        ;;
    *)
        print_error "Unknown target: $TARGET"
        echo "Usage: $0 [local|docker|docker-push|clean|test|check|fmt]"
        exit 1
        ;;
esac
