#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/nodejs-nestjs"
echo "=== Building Node.js nestjs ==="
case $TARGET in
    "local") npm install ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") rm -rf node_modules ;;
esac
