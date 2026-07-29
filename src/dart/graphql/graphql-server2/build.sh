#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="graphql-server2"
IMAGE_TAG="${1:-latest}"

cd "$SCRIPT_DIR"

echo "Building $IMAGE_NAME:$IMAGE_TAG..."
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

echo "Build complete: $IMAGE_NAME:$IMAGE_TAG"
