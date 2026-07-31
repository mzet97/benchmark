#!/bin/bash

echo "=========================================="
echo "Starting Benchmark API (Bun + Bun Serve)"
echo "=========================================="
echo ""

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo "❌ Bun is not installed"
    echo "Please install Bun: https://bun.sh"
    exit 1
fi

# Set environment variables
export PORT=${PORT:-3000}
export HOST=${HOST:-0.0.0.0}
export LOG_LEVEL=${LOG_LEVEL:-info}
export DEBUG=${DEBUG:-false}

# Default database and cache URLs
export DATABASE_URL=${DATABASE_URL:?DATABASE_URL is required}
export REDIS_URL=${REDIS_URL:?REDIS_URL is required}
export CACHE_TTL=${CACHE_TTL:-300}

echo "Configuration:"
echo "  Port: $PORT"
echo "  Host: $HOST"
echo "  Log Level: $LOG_LEVEL"
echo "  Database URL: $DATABASE_URL"
echo "  Redis URL: $REDIS_URL"
echo ""

# Start the server
echo "Starting server..."
bun run start
