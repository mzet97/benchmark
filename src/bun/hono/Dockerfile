FROM oven/bun:1.0 AS builder

WORKDIR /app

# Copy package files
COPY package.json bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Build TypeScript
RUN bun run build

# Production stage
FROM oven/bun:1.0-slim AS production

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create app user
RUN addgroup --system --gid 1001 honoapp && \
    adduser --system --uid 1001 --gid 1001 honoapp

# Copy package files
COPY package.json bun.lockb ./

# Install only production dependencies
RUN bun install --frozen-lockfile --production

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Switch to non-root user
USER honoapp

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["bun", "run", "start"]
