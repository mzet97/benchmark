#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="benchmark/java-dgs-graphql"
IMAGE_TAG="${1:-latest}"

echo "=== Building Java DGS GraphQL Benchmark ==="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

mvn clean package -DskipTests -B

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "=== Build complete: ${IMAGE_NAME}:${IMAGE_TAG} ==="
