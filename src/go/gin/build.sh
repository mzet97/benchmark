#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/go-gin"
echo "=== Building Go gin ==="
case $TARGET in
    "local") go build -o main . ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") rm -f main ;;
esac
