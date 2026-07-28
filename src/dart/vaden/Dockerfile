# Multi-stage build for Dart Shelf application
FROM dart:3.2 AS builder

WORKDIR /app

# Copy pubspec files first (for layer caching)
COPY pubspec.yaml ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY . .

# Build executable
RUN dart compile exe bin/server.dart -o server

# Production stage
FROM dart:3.2-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 dartapp && \
    adduser --system --uid 1001 --gid 1001 dartapp

# Copy server executable from builder
COPY --from=builder /app/server .

# Switch to non-root user
USER dartapp

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["./server"]
