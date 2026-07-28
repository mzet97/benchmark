#!/bin/bash
set -e

echo "=================================="
echo "Running Deno Fresh Application"
echo "=================================="

export PORT=${PORT:-3000}
export DATABASE_URL=${DATABASE_URL:-'postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api'}
export REDIS_URL=${REDIS_URL:-'redis://:Admin@123@redis.home.arpa:30379'}

deno run --allow-net --allow-env --allow-read server.ts
