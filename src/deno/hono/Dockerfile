# Multi-stage build for Deno Hono
FROM denoland/deno:2.0 AS builder

WORKDIR /app

# Copy dependency files first (for layer caching)
COPY deno.json .

# Copy source code
COPY . .

# Cache dependencies
RUN deno cache server.ts

# Production stage
FROM denoland/deno:2.0-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 denoapp && \
    adduser --system --uid 1001 --gid 1001 denoapp

# Copy deno.json and cached dependencies
COPY --from=builder /app/deno.json .
COPY --from=builder /deno-dir /deno-dir

# Copy application code
COPY --chown=denoapp:denoapp . .

USER denoapp

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "server.ts"]
