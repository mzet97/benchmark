#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/nodejs-express"
echo "=== Building Node.js Express ==="
case $TARGET in
    "local") npm install ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") rm -rf node_modules ;;
esac
