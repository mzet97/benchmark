#!/bin/bash

# Run script for Java Quarkus
# Usage: ./run.sh [mode]

set -e

MODE=${1:-"dev"}

echo "=========================================="
echo "Java Quarkus - Run Script"
echo "=========================================="
echo "Mode: $MODE"
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

case $MODE in
    "dev")
        print_info "Starting in development mode..."
        export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
        export REDIS_HOST="redis.home.arpa:30379"
        export REDIS_PASSWORD="Admin@123"
        mvn quarkus:dev
        ;;

    "local-jvm")
        print_info "Running JAR locally..."
        if [ ! -f "./target/benchmark-quarkus-1.0.0-runner.jar" ]; then
            print_info "Building JAR first..."
            mvn clean package -DskipTests
        fi
        java -jar ./target/benchmark-quarkus-1.0.0-runner.jar
        ;;

    "local-native")
        print_info "Running native binary locally..."
        if [ ! -f "./target/benchmark-quarkus-1.0.0-runner" ]; then
            print_info "Building native binary first..."
            mvn clean package -Pnative -DskipTests
        fi
        ./target/benchmark-quarkus-1.0.0-runner
        ;;

    "docker")
        print_info "Running via Docker..."
        docker run -it --rm \
            -p 8080:8080 \
            -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
            -e REDIS_HOST="redis.home.arpa:30379" \
            -e REDIS_PASSWORD="Admin@123" \
            benchmark/java-quarkus:latest
        ;;

    "docker-jvm")
        print_info "Running JVM Docker image..."
        docker run -it --rm \
            -p 8080:8080 \
            -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
            -e REDIS_HOST="redis.home.arpa:30379" \
            -e REDIS_PASSWORD="Admin@123" \
            benchmark/java-quarkus:jvm
        ;;

    *)
        echo "Usage: $0 {dev|local-jvm|local-native|docker|docker-jvm}"
        echo ""
        echo "Modes:"
        echo "  dev        - Development mode with hot reload"
        echo "  local-jvm  - Run JAR locally"
        echo "  local-native - Run native binary locally"
        echo "  docker     - Run via Docker (native)"
        echo "  docker-jvm - Run via Docker (JVM)"
        exit 1
        ;;
esac
