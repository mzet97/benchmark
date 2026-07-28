#!/bin/bash
set -euo pipefail

IMAGE_NAME="benchmark-graalvm-helidon"
CONTAINER_NAME="benchmark-graalvm-helidon"

echo "Building ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" .

echo "Stopping existing container (if any)..."
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

echo "Running ${CONTAINER_NAME}..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p 3000:3000 \
    -e DATABASE_URL="${DATABASE_URL:-jdbc:postgresql://host.docker.internal:5432/benchmark_api}" \
    -e REDIS_URL="${REDIS_URL:-redis://host.docker.internal:6379}" \
    "${IMAGE_NAME}"

echo "Container started. Access at http://localhost:3000"
