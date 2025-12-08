#!/bin/bash

# Build script for Kotlin Ktor
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/kotlin-ktor"
IMAGE_TAG="latest"

echo "=========================================="
echo "Kotlin Ktor - Build Script"
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

# Check if Java is installed
if ! command -v java &> /dev/null; then
    print_error "Java not found. Please install Java 21 or later."
    exit 1
fi

print_info "Java version: $(java -version 2>&1 | head -n 1)"

# Check if Gradle is installed
if ! command -v gradle &> /dev/null; then
    print_error "Gradle not found. Please install Gradle."
    exit 1
fi

print_info "Gradle version: $(gradle --version | grep Gradle)"

case $TARGET in
    "local")
        print_info "Building for local development..."
        gradle build --no-daemon
        print_success "Build complete: ./build/libs/benchmark-ktor.jar"
        print_info "Run with: java -jar ./build/libs/benchmark-ktor.jar"
        ;;

    "docker")
        print_info "Building Docker image..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 8080:8080 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        gradle clean
        rm -rf build/
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        gradle test --no-daemon
        print_success "Tests complete"
        ;;

    "fatJar")
        print_info "Building fat JAR..."
        gradle fatJar --no-daemon
        print_success "Fat JAR created: ./build/libs/benchmark-ktor.jar"
        ;;

    "docker-push")
        print_info "Pushing Docker image..."
        docker push $IMAGE_NAME:$IMAGE_TAG
        print_success "Image pushed: $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "install-deps")
        print_info "Installing dependencies..."
        gradle build --refresh-dependencies --no-daemon
        print_success "Dependencies installed"
        ;;

    *)
        echo "Usage: $0 {local|docker|clean|test|fatJar|docker-push|install-deps}"
        echo ""
        echo "Targets:"
        echo "  local          - Build for local development"
        echo "  docker         - Build Docker image"
        echo "  clean          - Clean build artifacts"
        echo "  test           - Run tests"
        echo "  fatJar         - Build fat JAR"
        echo "  docker-push    - Push Docker image to registry"
        echo "  install-deps   - Install dependencies"
        exit 1
        ;;
esac
