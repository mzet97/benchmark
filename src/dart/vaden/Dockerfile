# Multi-stage build for Dart application
FROM dart:3.2 AS builder

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY . .

# Build executable
RUN dart compile exe bin/server.dart -o server

# Production stage
FROM dart:3.2-slim AS production

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create app user
RUN addgroup --system --gid 1001 dartapp && \
    adduser --system --uid 1001 --gid 1001 dartapp

# Copy pubspec files
COPY pubspec.yaml ./

# Install only production dependencies
RUN dart pub get --only=production

# Copy server executable from builder
COPY --from=builder /app/server .

# Copy Dart runtime
COPY --from=builder /usr/lib/dart /usr/lib/dart

# Switch to non-root user
USER dartapp

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["./server"]
