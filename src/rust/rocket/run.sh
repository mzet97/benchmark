#!/bin/bash
docker run -d --name rust-rocket-app -p 3000:3000 \
  -e DATABASE_URL="postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api" \
  -e REDIS_URL="redis://:Admin@123@redis.home.arpa:30379" \
  benchmark/rust-rocket:latest
