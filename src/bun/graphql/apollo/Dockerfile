FROM oven/bun:latest AS builder

WORKDIR /app

COPY package.json bun.lockb* ./

RUN bun install --frozen-lockfile 2>/dev/null || bun install

COPY . .

# Production stage
FROM oven/bun:latest

WORKDIR /app

RUN groupadd -r bunapp && useradd -r -g bunapp -u 1001 bunapp

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/package.json ./

USER bunapp

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["bun", "run", "src/index.js"]
