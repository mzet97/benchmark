#!/bin/bash
set -e

echo "=================================="
echo "Building Dart Vaden Application"
echo "=================================="

# Configuration
IMAGE_NAME="benchmark/dart-vaden"
TAG="${TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Check if dart is installed
if ! command -v dart &> /dev/null; then
    echo "Error: Dart is not installed"
    echo "Install Dart: https://dart.dev/tools"
    exit 1
fi

# Get dependencies
echo "Getting dependencies..."
dart pub get

if [ $? -ne 0 ]; then
    echo "✗ Failed to get dependencies"
    exit 1
fi

echo "✓ Dependencies installed"

# Generate code
echo "Generating code..."
dart run build_runner build --delete-conflicting-outputs

if [ $? -ne 0 ]; then
    echo "✗ Failed to generate code"
    exit 1
fi

echo "✓ Code generated"

# Docker build
echo "Building Docker image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

if [ $? -eq 0 ]; then
    echo "✓ Docker build successful"
    echo "Image: ${FULL_IMAGE}"
    echo ""
    echo "To run the container:"
    echo "  docker run -d --name dart-vaden-app -p 3000:3000 \\"
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
