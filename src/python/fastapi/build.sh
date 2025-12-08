#!/bin/bash
set -e

echo "=================================="
echo "Building Python FastAPI Application"
echo "=================================="

# Configuration
IMAGE_NAME="benchmark/python-fastapi"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Docker build
echo "Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ $? -eq 0 ]; then
    echo "✓ Docker build successful"
    echo "Image: ${FULL_IMAGE}"
    echo ""
    echo "To run the container:"
    echo "  docker run -d --name fastapi-app -p 8000:8000 \\"
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
