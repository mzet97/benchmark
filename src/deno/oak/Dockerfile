# Multi-stage build for Deno application
FROM denoland/deno:2 AS builder

# Set working directory
WORKDIR /app

# Copy configuration files
COPY deno.json .
COPY deps.ts .

# Cache dependencies
RUN deno cache deps.ts

# Copy source code
COPY . .

# Production stage
FROM denoland/deno:2-slim AS production

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Create app user
RUN addgroup --system --gid 1001 denoapp && \
    adduser --system --uid 1001 --gid 1001 denoapp

# Copy configuration files
COPY deno.json .

# Copy dependencies cache from builder
COPY --from=builder /app/deps.ts .

# Cache dependencies
RUN deno cache --quiet deps.ts

# Copy application code
COPY --chown=denoapp:denoapp . .

# Switch to non-root user
USER denoapp

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "server.ts"]
