#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/deno-deno-serve"
echo "=== Building Deno Native Serve ==="
case $TARGET in
    "local") deno cache server.ts ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") deno cache --reload server.ts ;;
esac
