#!/bin/bash
docker run -d --name rust-rocket-app -p 3000:3000 \
  -e DATABASE_URL="${DATABASE_URL:?DATABASE_URL is required}" \
  -e REDIS_URL="${REDIS_URL:?REDIS_URL is required}" \
  benchmark/rust-rocket:latest
