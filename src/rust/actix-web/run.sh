#!/bin/bash

# Run script for Rust Actix Web
# Usage: ./run.sh [mode]

set -e

MODE=${1:-"dev"}

echo "=========================================="
echo "Rust Actix Web - Run Script"
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
if [ ! -f "./target/release/benchmark-actix" ]; then
    print_info "Binary not found. Building..."
    cargo build --release
fi

case $MODE in
    "dev")
        print_info "Starting in development mode..."
        export RUST_LOG=debug
        export DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"
        export REDIS_URL="redis://:Admin@123@redis.home.arpa:30379"
        export SERVER_WORKERS=4
        ./target/release/benchmark-actix
        ;;

    "prod")
        print_info "Starting in production mode..."
        ./target/release/benchmark-actix
        ;;

    "docker")
        print_info "Running via Docker..."
        docker run -it --rm \
            -p 8080:8080 \
            -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
            -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
            benchmark/rust-actix-web:latest
        ;;

    *)
        echo "Usage: $0 {dev|prod|docker}"
        echo ""
        echo "Modes:"
        echo "  dev   - Development mode with debug logging"
        echo "  prod  - Production mode"
        echo "  docker - Run via Docker"
        exit 1
        ;;
esac
