#!/bin/bash

# Run script for Go Fiber
# Usage: ./run.sh [mode]

set -e

MODE=${1:-"dev"}

echo "=========================================="
echo "Go Fiber - Run Script"
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

# Check if binary exists
if [ ! -f "./bin/server" ]; then
    print_info "Binary not found. Building..."
    ./build.sh local
fi

case $MODE in
    "dev")
        print_info "Starting in development mode..."
        export PORT=8080
        export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
        export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
        export GIN_MODE=debug
        ./bin/server
        ;;

    "prod")
        print_info "Starting in production mode..."
        export PORT=8080
        ./bin/server
        ;;

    "docker")
        print_info "Running via Docker..."
        docker run -it --rm \
            -p 8080:8080 \
            -e PORT=8080 \
            -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
            -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
            benchmark/go-fiber:latest
        ;;

    "race")
        print_info "Running with race detector..."
        export PORT=8080
        export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
        export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
        ./bin/server-race
        ;;

    *)
        echo "Usage: $0 {dev|prod|docker|race}"
        echo ""
        echo "Modes:"
        echo "  dev   - Development mode with debug logging"
        echo "  prod  - Production mode"
        echo "  docker - Run via Docker"
        echo "  race  - Run with race detector"
        exit 1
        ;;
esac
