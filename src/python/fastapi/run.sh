#!/bin/bash
set -e

echo "=================================="
echo "Running Python FastAPI Application"
echo "=================================="

# Configuration
CONTAINER_NAME="python-fastapi-app"
IMAGE_NAME="benchmark/python-fastapi"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

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
    -p 8000:8000 \
    -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
    -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
    -e DEBUG="false" \
    -e LOG_LEVEL="INFO" \
    --health-cmd='curl -f http://localhost:8000/health || exit 1' \
    --health-interval=30s \
    --health-timeout=3s \
    --health-retries=3 \
    ${FULL_IMAGE}

echo ""
echo "✓ Container started successfully"
echo ""
echo "Container name: ${CONTAINER_NAME}"
echo "Port: 8000"
echo ""
echo "API Endpoints:"
echo "  Health:  http://localhost:8000/health"
echo "  JSON:    http://localhost:8000/json"
echo "  DB Simple: http://localhost:8000/db/simple?id=1"
echo "  DB Complex: http://localhost:8000/db/complex?days=30"
echo "  Cache:   http://localhost:8000/cache?key=test"
echo ""
echo "Documentation:"
echo "  Swagger UI: http://localhost:8000/docs"
echo "  ReDoc: http://localhost:8000/redoc"
echo ""
echo "To view logs:"
echo "  docker logs -f ${CONTAINER_NAME}"
echo ""
echo "To stop:"
echo "  docker stop ${CONTAINER_NAME}"
