#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/kotlin-spring"
echo "=== Building Kotlin spring ==="
case $TARGET in
    "local") ./gradlew build ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") ./gradlew clean ;;
esac
