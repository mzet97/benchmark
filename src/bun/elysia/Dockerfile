FROM oven/bun:1 AS builder
WORKDIR /app
COPY package.json ./
RUN bun install
COPY . .

FROM oven/bun:1
RUN addgroup -g 1001 -S bun && adduser -S bun -u 1001
WORKDIR /app
COPY --from=builder --chown=bun:bun /app .
USER bun
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["bun", "run", "src/server.ts"]
