#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/kotlin-http4k"
echo "=== Building Kotlin http4k ==="
case $TARGET in
    "local") ./gradlew build ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") ./gradlew clean ;;
esac
