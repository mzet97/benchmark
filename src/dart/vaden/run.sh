#!/bin/bash
set -e

echo "=================================="
echo "Running Dart Vaden Application"
echo "=================================="

# Configuration
CONTAINER_NAME="dart-vaden-app"
IMAGE_NAME="benchmark/dart-vaden"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Check if dart is installed
if ! command -v dart &> /dev/null; then
    echo "Error: Dart is not installed"
    echo "Install Dart: https://dart.dev/tools"
    exit 1
fi

# Check if container is already running
if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
    echo "Container ${CONTAINER_NAME} is already running"
    echo "Stopping and removing it..."
    docker stop ${CONTAINER_NAME} > /dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} > /dev/null 2>&1 || true
fi

# Run container
echo "Starting container..."
docker run -d \
    --name ${CONTAINER_NAME} \
    -p 3000:3000 \
    -e DATABASE_URL="${DATABASE_URL:?DATABASE_URL is required}" \
    -e REDIS_URL="${REDIS_URL:?REDIS_URL is required}" \
    -e DEBUG="false" \
    -e LOG_LEVEL="info" \
    -e PORT="3000" \
    -e HOST="0.0.0.0" \
    --health-cmd='curl -f http://localhost:3000/health || exit 1' \
    --health-interval=30s \
    --health-timeout=3s \
    --health-retries=3 \
    ${FULL_IMAGE}

echo ""
echo "✓ Container started successfully"
echo ""
echo "Container name: ${CONTAINER_NAME}"
echo "Port: 3000"
echo ""
echo "API Endpoints:"
echo "  Health:  http://localhost:3000/health"
echo "  JSON:    http://localhost:3000/json"
echo "  DB Simple: http://localhost:3000/db/simple?id=1"
echo "  DB Complex: http://localhost:3000/db/complex?days=30"
echo "  Cache:   http://localhost:3000/cache?key=test"
echo ""
echo "To view logs:"
echo "  docker logs -f ${CONTAINER_NAME}"
echo ""
echo "To stop:"
echo "  docker stop ${CONTAINER_NAME}"
