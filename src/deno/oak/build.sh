#!/bin/bash
set -e

echo "=================================="
echo "Building Deno Oak Application"
echo "=================================="

# Configuration
IMAGE_NAME="benchmark/deno-oak"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Check if deno is installed
if ! command -v deno &> /dev/null; then
    echo "Error: Deno is not installed"
    echo "Install Deno: https://deno.land/manual/getting_startup/installation"
    exit 1
fi

# Cache dependencies
echo "Caching dependencies..."
deno cache deps.ts

if [ $? -ne 0 ]; then
    echo "✗ Failed to cache dependencies"
    exit 1
fi

echo "✓ Dependencies cached"

# Docker build
echo "Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ $? -eq 0 ]; then
    echo "✓ Docker build successful"
    echo "Image: ${FULL_IMAGE}"
    echo ""
    echo "To run the container:"
    echo "  docker run -d --name deno-oak-app -p 3000:3000 \\"
    echo "    -e DATABASE_URL='postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api' \\"
    echo "    -e REDIS_URL='redis://:Admin@123@redis.home.arpa:30379' \\"
    echo "    ${FULL_IMAGE}"
    echo ""
    echo "To push to registry:"
    echo "  docker push ${FULL_IMAGE}"
else
    echo "✗ Docker build failed"
    exit 1
fi
