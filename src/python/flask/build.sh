#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/python-flask"
echo "=== Building Python flask ==="
case $TARGET in
    "local") pip install -r requirements.txt ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") rm -rf venv ;;
esac
