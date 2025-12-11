#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/graalvm-micronaut"
echo "=== Building GraalVM micronaut ==="
case $TARGET in
    "local") mvn clean package -DskipTests -Pnative ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") mvn clean ;;
esac
