FROM oven/bun:latest AS builder
WORKDIR /app
COPY package.json ./
RUN bun install
COPY . .

FROM oven/bun:latest
RUN groupadd -g 1001 hono 2>/dev/null || true && useradd -r -g hono -u 1001 hono 2>/dev/null || true
WORKDIR /app
COPY --from=builder --chown=hono:hono /app .
USER hono
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
CMD ["bun", "run", "src/index.ts"]
