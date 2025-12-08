#!/bin/bash

# Build script for Java Quarkus Native Image
# Usage: ./build.sh [target]

set -e

TARGET=${1:-"local"}
IMAGE_NAME="benchmark/java-quarkus"
IMAGE_TAG="latest"

echo "=========================================="
echo "Java Quarkus - Build Script"
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
if ! command -v mvn &> /dev/null; then
    print_error "Maven not found. Installing Maven..."
    # Maven will be installed in Docker build anyway
fi

case $TARGET in
    "local-jvm")
        print_info "Building for local JVM..."
        mvn clean package -DskipTests
        print_success "Build complete: ./target/benchmark-quarkus-1.0.0-runner.jar"
        print_info "Run with: java -jar ./target/benchmark-quarkus-1.0.0-runner.jar"
        ;;

    "local-native")
        print_info "Building native binary locally (requires GraalVM)..."
        mvn clean package -Pnative -DskipTests
        print_success "Native binary created: ./target/benchmark-quarkus-1.0.0-runner"
        ;;

    "docker")
        print_info "Building Docker image with native compilation..."
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        print_success "Docker image created: $IMAGE_NAME:$IMAGE_TAG"
        print_info "Run with: docker run -p 8080:8080 $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "docker-jvm")
        print_info "Building Docker image for JVM..."
        cat > Dockerfile.jvm << 'EOF'
FROM registry.access.redhat.com/ubi8/openjdk-21-runtime:latest

COPY target/*-runner.jar /deployments/app.jar

EXPOSE 8080
ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.library.path=/deployments/lib"
CMD ["java", "-jar", "/deployments/app.jar"]
EOF
        docker build -f Dockerfile.jvm -t $IMAGE_NAME:jvm .
        rm -f Dockerfile.jvm
        print_success "JVM Docker image created: $IMAGE_NAME:jvm"
        ;;

    "clean")
        print_info "Cleaning build artifacts..."
        mvn clean
        rm -rf target/
        rm -f Dockerfile.jvm
        print_success "Clean complete"
        ;;

    "test")
        print_info "Running tests..."
        mvn test
        print_success "Tests complete"
        ;;

    "native-test")
        print_info "Running tests with native profile..."
        mvn test -Pnative
        print_success "Native tests complete"
        ;;

    "fmt")
        print_info "Formatting code..."
        mvn fmt:format
        print_success "Format complete"
        ;;

    "docker-push")
        print_info "Pushing Docker image..."
        docker push $IMAGE_NAME:$IMAGE_TAG
        print_success "Image pushed: $IMAGE_NAME:$IMAGE_TAG"
        ;;

    "check")
        print_info "Running code quality checks..."
        mvn checkstyle:check
        mvn spotbugs:check
        print_success "Quality checks complete"
        ;;

    *)
        echo "Usage: $0 {local-jvm|local-native|docker|docker-jvm|clean|test|native-test|fmt|docker-push|check}"
        echo ""
        echo "Targets:"
        echo "  local-jvm       - Build JAR for local JVM"
        echo "  local-native    - Build native binary (requires GraalVM)"
        echo "  docker          - Build Docker native image"
        echo "  docker-jvm      - Build Docker JVM image"
        echo "  clean           - Clean build artifacts"
        echo "  test            - Run tests"
        echo "  native-test     - Run tests with native profile"
        echo "  fmt             - Format code"
        echo "  docker-push     - Push Docker image to registry"
        echo "  check           - Run code quality checks"
        exit 1
        ;;
esac
