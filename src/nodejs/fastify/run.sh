#!/bin/bash

# Run script for Node.js Fastify
# Usage: ./run.sh [mode]

set -e

MODE=${1:-"dev"}

echo "=========================================="
echo "Node.js Fastify - Run Script"
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

# Check if dependencies are installed
if [ ! -d "./node_modules" ]; then
    print_info "Dependencies not found. Installing..."
    npm install
fi

case $MODE in
    "dev")
        print_info "Starting in development mode..."
        export PORT=8080
        export NODE_ENV=development
        export LOG_LEVEL=debug
        export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
        export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
        npm run dev
        ;;

    "start")
        print_info "Starting in production mode..."
        export PORT=8080
        export NODE_ENV=production
        export LOG_LEVEL=info
        npm start
        ;;

    "docker")
        print_info "Running via Docker..."
        docker run -it --rm \
            -p 8080:8080 \
            -e PORT=8080 \
            -e NODE_ENV=production \
            -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
            -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
            benchmark/nodejs-fastify:latest
        ;;

    "test")
        print_info "Running tests..."
        npm test
        ;;

    *)
        echo "Usage: $0 {dev|start|docker|test}"
        echo ""
        echo "Modes:"
        echo "  dev   - Development mode with hot reload"
        echo "  start - Production mode"
        echo "  docker - Run via Docker"
        echo "  test - Run tests"
        exit 1
        ;;
esac
