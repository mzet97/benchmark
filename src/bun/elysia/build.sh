#!/bin/bash
set -e

echo "=================================="
echo "Building Bun Elysia Application"
echo "=================================="

# Configuration
IMAGE_NAME="benchmark/bun-elysia"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo "Error: Bun is not installed"
    echo "Install Bun: https://bun.sh"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
bun install

if [ $? -ne 0 ]; then
    echo "✗ Failed to install dependencies"
    exit 1
fi

echo "✓ Dependencies installed"

# Docker build
echo "Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ $? -eq 0 ]; then
    echo "✓ Docker build successful"
    echo "Image: ${FULL_IMAGE}"
    echo ""
    echo "To run the container:"
    echo "  docker run -d --name bun-elysia-app -p 3000:3000 \\"
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
