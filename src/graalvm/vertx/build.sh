#!/bin/bash

# Build script for GraalVM Vert.x
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/graalvm-vertx"
IMAGE_TAG="latest"

echo "=========================================="
echo "GraalVM Vert.x - Build Script"
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

# Check if Maven is installed
check_maven() {
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed"
        echo "Install Maven: https://maven.apache.org"
        exit 1
    fi
}

case $TARGET in
    "local")
        print_info "Building for local development..."
        check_maven

        print_info "Building JAR..."
        mvn clean package -DskipTests

        if [ $? -eq 0 ]; then
            print_success "Build complete: target/graalvm-vertx-benchmark-1.0.0.jar"
        else
            print_error "Build failed"
            exit 1
        fi
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 3000:3000 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        mvn clean
        rm -rf target/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        mvn test
        print_success "Tests complete"
        ;;

    "check")
        print_info "Checking code format..."
        mvn spotless:check || print_info "Spotless not configured"
        print_success "Format check complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        mvn spotless:apply || print_info "Spotless not configured"
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
        echo "  local        - Build for local development (target/*.jar)"
        echo "  docker       - Build Docker image (benchmark/graalvm-vertx:latest)"
        echo "  clean        - Clean build artifacts"
        echo "  test         - Run tests"
        echo "  check        - Verify formatting"
        echo "  fmt          - Format code"
        echo "  docker-push  - Push Docker image to registry"
        exit 1
        ;;
esac
