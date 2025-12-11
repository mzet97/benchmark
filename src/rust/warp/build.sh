#!/bin/bash
TARGET=${1:-"local"}
case $TARGET in
    "local") cargo build --release ;;
    "docker") docker build -t benchmark/rust-warp:latest . ;;
esac
