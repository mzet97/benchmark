#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
IMAGE_NAME="benchmark-connectrpc"
IMAGE_TAG="${1:-latest}"

echo "=== Building Go ConnectRPC server ==="

# Proto code generation is handled inside the Dockerfile
echo "Proto code will be generated during Docker build"

# Build Docker image
echo "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
docker build \
  -f "$SCRIPT_DIR/Dockerfile" \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  "$PROJECT_ROOT"

echo "=== Build complete: $IMAGE_NAME:$IMAGE_TAG ==="
