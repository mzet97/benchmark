#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="benchmark/smallrye-graphql-native"
IMAGE_TAG="${1:-latest}"

echo "=== Building SmallRye GraphQL Native Benchmark ==="
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

docker run --rm -v "$(pwd)":/app -w /app \
    quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 \
    mvn package -Dnative -DskipTests -B

docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "=== Build complete: ${IMAGE_NAME}:${IMAGE_TAG} ==="
