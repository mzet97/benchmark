#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="benchmark/nice-grpc"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=== Building Node.js nice-grpc server ==="
echo "Directory: ${SCRIPT_DIR}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

cd "${SCRIPT_DIR}"

# Install dependencies
echo "Installing dependencies..."
npm ci

# Build Docker image
echo "Building Docker image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "=== Build complete: ${IMAGE_NAME}:${IMAGE_TAG} ==="
