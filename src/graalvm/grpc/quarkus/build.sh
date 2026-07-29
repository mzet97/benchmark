#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="benchmark/graalvm-grpc-quarkus"
IMAGE_TAG="${1:-latest}"

echo "=== Building GraalVM Quarkus gRPC Native ==="
echo "Directory: ${SCRIPT_DIR}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

cd "${SCRIPT_DIR}"

docker build \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  -f Dockerfile \
  .

echo ""
echo "=== Build complete: ${IMAGE_NAME}:${IMAGE_TAG} ==="
echo ""
echo "To run locally:"
echo "  docker run -p 50051:50051 ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To deploy to Kubernetes:"
echo "  kubectl apply -f k8s/"
