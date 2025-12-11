#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/graalvm-helidon"
echo "=== Building GraalVM helidon ==="
case $TARGET in
    "local") mvn clean package -DskipTests -Pnative ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") mvn clean ;;
esac
