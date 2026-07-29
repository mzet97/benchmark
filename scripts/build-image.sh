#!/usr/bin/env bash
# build-image.sh
# Builds a Docker image for a specific implementation.
#
# Usage:
#   ./scripts/build-image.sh <implementation-id>
#   ./scripts/build-image.sh rust-rest-actix-web
#   ./scripts/build-image.sh dart-rest-vaden

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$ROOT_DIR/config/implementations.yaml"

IMPL_ID="${1:?Usage: $0 <implementation-id>}"

# Get git SHA for immutable tag
GIT_SHA="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo 'latest')"

# Find implementation in config
FOUND=false
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]*-\ id:\ $IMPL_ID$ ]]; then
    FOUND=true
  elif [ "$FOUND" = true ] && [[ "$line" =~ ^[[:space:]]*path:\ (.+)$ ]]; then
    IMPL_PATH="${BASH_REMATCH[1]}"
    IMPL_PATH="$(echo "$IMPL_PATH" | xargs)"
    break
  fi
done < "$CONFIG"

if [ "$FOUND" = false ] || [ -z "${IMPL_PATH:-}" ]; then
  echo "ERROR: Implementation '$IMPL_ID' not found in $CONFIG"
  exit 1
fi

DOCKERFILE="$ROOT_DIR/$IMPL_PATH/Dockerfile"
if [ ! -f "$DOCKERFILE" ]; then
  echo "ERROR: Dockerfile not found at $DOCKERFILE"
  exit 1
fi

IMAGE_NAME="benchmark/$IMPL_ID"
IMAGE_TAG="$GIT_SHA"
IMAGE="$IMAGE_NAME:$IMAGE_TAG"
IMAGE_LATEST="$IMAGE_NAME:latest"

echo "========================================="
echo "  Building Image"
echo "========================================="
echo "Implementation: $IMPL_ID"
echo "Path:           $IMPL_PATH"
echo "Image:          $IMAGE"
echo "Dockerfile:     $DOCKERFILE"
echo "========================================="

docker build -t "$IMAGE" -t "$IMAGE_LATEST" -f "$DOCKERFILE" "$ROOT_DIR/$IMPL_PATH"

echo ""
echo "✅ Image built: $IMAGE"
echo "✅ Image tagged: $IMAGE_LATEST"
echo ""
echo "Image size:"
docker images "$IMAGE_NAME" --format "  {{.Repository}}:{{.Tag}}  {{.Size}}"
