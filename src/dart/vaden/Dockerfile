# Stage 1: Build
FROM dart:3.5.0 AS builder
WORKDIR /app

# Copy everything first
COPY . .

# Resolve dependencies (needs source for local package refs)
RUN dart pub get

# Compile to native executable (AOT)
RUN dart compile exe bin/server.dart -o server

# Stage 2: Production
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN groupadd -r dartapp && useradd -r -g dartapp -u 1001 dartapp
WORKDIR /app
COPY --from=builder --chown=dartapp:dartapp /app/server .
USER dartapp
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
CMD ["./server"]
