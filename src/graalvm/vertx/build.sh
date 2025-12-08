#!/bin/bash
set -e

echo "=================================="
echo "Building GraalVM Vert.x Application"
echo "=================================="

# Configuration
IMAGE_NAME="benchmark/graalvm-vertx"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "Error: Maven is not installed"
    echo "Install Maven: https://maven.apache.org/install.html"
    exit 1
fi

# Build JAR
echo "Building JAR..."
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "✗ Failed to build JAR"
    exit 1
fi

echo "✓ JAR built successfully"

# Docker build
echo "Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ $? -eq 0 ]; then
    echo "✓ Docker build successful"
    echo "Image: ${FULL_IMAGE}"
    echo ""
    echo "To run the container:"
    echo "  docker run -d --name graalvm-vertx-app -p 3000:3000 \\"
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
