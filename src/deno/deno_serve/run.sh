#!/bin/bash
set -e

export PORT=${PORT:-3000}
export DATABASE_URL=${DATABASE_URL:-'postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api'}
export REDIS_URL=${REDIS_URL:-'redis://:Admin@123@redis.home.arpa:30379'}

# Run the application
exec deno run --allow-net --allow-env server.ts
