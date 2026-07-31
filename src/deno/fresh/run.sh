#!/bin/bash
set -e

echo "=================================="
echo "Running Deno Fresh Application"
echo "=================================="

export PORT=${PORT:-3000}
export DATABASE_URL=${DATABASE_URL:?DATABASE_URL is required}
export REDIS_URL=${REDIS_URL:?REDIS_URL is required}

deno run --allow-net --allow-env --allow-read server.ts
