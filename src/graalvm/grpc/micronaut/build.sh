#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/graalvm-micronaut-grpc"

echo "=== Building GraalVM Micronaut gRPC Native ==="

case $TARGET in
    "local")
        mvn clean package -DskipTests -Pnative
        ;;
    "docker")
        docker build -t $IMAGE_NAME:latest .
        ;;
    "clean")
        mvn clean
        ;;
    *)
        echo "Usage: ./build.sh [local|docker|clean]"
        exit 1
        ;;
esac
