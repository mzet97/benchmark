#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="benchmark/grpc-kotlin-spring"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=== Building Kotlin Spring gRPC server ==="
echo "Directory: ${SCRIPT_DIR}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

cd "${SCRIPT_DIR}"

# Build with Gradle
echo "Building with Gradle..."
if command -v gradle &> /dev/null; then
    gradle jar --no-daemon
elif [ -f "./gradlew" ]; then
    ./gradlew jar --no-daemon
else
    echo "Gradle wrapper not found, building with Docker..."
    docker run --rm -v "$(pwd):/app" -w /app gradle:8.5-jdk17 gradle jar --no-daemon
fi

# Build Docker image
echo "Building Docker image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "=== Build complete: ${IMAGE_NAME}:${IMAGE_TAG} ==="
