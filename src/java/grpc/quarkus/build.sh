#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="benchmark/grpc-java-quarkus"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=== Building Java Quarkus gRPC server ==="
echo "Directory: ${SCRIPT_DIR}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

cd "${SCRIPT_DIR}"

# Build with Maven
echo "Building with Maven..."
if command -v mvn &> /dev/null; then
    mvn clean package -DskipTests --no-transfer-progress
else
    echo "Maven not found, building with Docker..."
    docker run --rm -v "$(pwd):/app" -w /app maven:3.9-eclipse-temurin-17 mvn clean package -DskipTests --no-transfer-progress
fi

# Build Docker image
echo "Building Docker image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "=== Build complete: ${IMAGE_NAME}:${IMAGE_TAG} ==="
