#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="benchmark/python-grpc-grpcio:latest"

echo "=== Building Python grpcio benchmark ==="
echo "Context: ${SCRIPT_DIR}"

# Generate stubs locally first
cd "${SCRIPT_DIR}"
pip install grpcio-tools --quiet
python generate.py

# Build Docker image
docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"

echo "=== Build complete: ${IMAGE_NAME} ==="
