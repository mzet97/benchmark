#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="benchmark/dart-grpc-grpc-dart:latest"

echo "=== Building Dart grpc-dart benchmark ==="
echo "Context: ${SCRIPT_DIR}"

# Generate protobuf stubs locally
cd "${SCRIPT_DIR}"

if command -v dart &>/dev/null; then
    dart pub get
    dart pub global activate protoc_plugin 2>/dev/null || true
    export PATH="$PATH:$HOME/.pub-cache/bin"
    if command -v protoc &>/dev/null; then
        protoc \
            --dart_out=grpc:lib/src \
            --proto_path=protos \
            protos/benchmark.proto
        echo "Generated protobuf stubs."
    else
        echo "protoc not found, stubs will be generated in Docker build."
    fi
fi

# Build Docker image
docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"

echo "=== Build complete: ${IMAGE_NAME} ==="
