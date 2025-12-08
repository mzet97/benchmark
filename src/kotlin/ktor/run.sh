#!/bin/bash

# Run script for Kotlin Ktor
# Usage: ./run.sh [mode]

set -e

MODE=${1:-"dev"}

echo "=========================================="
echo "Kotlin Ktor - Run Script"
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

# Check if JAR exists
if [ ! -f "./build/libs/benchmark-ktor.jar" ]; then
    print_info "JAR not found. Building..."
    ./build.sh local
fi

case $MODE in
    "dev")
        print_info "Starting in development mode..."
        export PORT=8080
        export DATABASE_URL="jdbc:postgresql://spsql.home.arpa:5432/benchmark_api"
        export DATABASE_USER="app"
        export DATABASE_PASSWORD="Admin@123"
        export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
        java -XX:+UseG1GC -Xms128m -Xmx512m -jar ./build/libs/benchmark-ktor.jar
        ;;

    "prod")
        print_info "Starting in production mode..."
        export PORT=8080
        java -XX:+UseG1GC -Xms256m -Xmx1024m -jar ./build/libs/benchmark-ktor.jar
        ;;

    "docker")
        print_info "Running via Docker..."
        docker run -it --rm \
            -p 8080:8080 \
            -e PORT=8080 \
            -e DATABASE_URL="jdbc:postgresql://spsql.home.arpa:5432/benchmark_api" \
            -e DATABASE_USER="app" \
            -e DATABASE_PASSWORD="Admin@123" \
            -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
            benchmark/kotlin-ktor:latest
        ;;

    *)
        echo "Usage: $0 {dev|prod|docker}"
        echo ""
        echo "Modes:"
        echo "  dev   - Development mode"
        echo "  prod  - Production mode"
        echo "  docker - Run via Docker"
        exit 1
        ;;
esac
