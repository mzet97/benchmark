#!/bin/bash
set -e
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/java-micronaut"
echo "=== Building Java micronaut ==="
case $TARGET in
    "local") mvn clean package -DskipTests ;;
    "docker") docker build -t $IMAGE_NAME:latest . ;;
    "clean") mvn clean ;;
esac
