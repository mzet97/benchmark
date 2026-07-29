# Stage 1: Build
FROM dart:3.5.0 AS builder
WORKDIR /app

# Copy pubspec and resolve dependencies
COPY pubspec.yaml ./
RUN dart pub get

# Copy source code
COPY . .

# Compile to native executable (AOT)
RUN dart compile exe bin/server.dart -o server

# Stage 2: Production
FROM dart:3.5.0
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
RUN groupadd --system --gid 1001 dartapp && useradd --system --uid 1001 --gid 1001 dartapp
WORKDIR /app
COPY --from=builder /app/server .
RUN chown dartapp:dartapp ./server
USER dartapp
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
CMD ["./server"]
