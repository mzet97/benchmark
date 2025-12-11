#!/bin/bash
TARGET=${1:-"local"}
IMAGE_NAME="benchmark/rust-rocket"

case $TARGET in
    "local")
        cargo build --release
        echo "Build complete: ./target/release/benchmark-rocket"
        ;;
    "docker")
        docker build -t $IMAGE_NAME:latest .
        ;;
    "clean")
        cargo clean
        ;;
esac
