FROM oven/bun:latest AS builder
WORKDIR /app
COPY package.json ./
RUN bun install
COPY . .

FROM oven/bun:latest
RUN groupadd -g 1001 bun 2>/dev/null || true && useradd -r -g bun -u 1001 bun 2>/dev/null || true
WORKDIR /app
COPY --from=builder --chown=bun:bun /app .
USER bun
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
CMD ["bun", "run", "src/index.ts"]
