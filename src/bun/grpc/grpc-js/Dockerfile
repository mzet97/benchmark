FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile --production 2>/dev/null || bun install --production

# Copy source
COPY proto/ ./proto/
COPY src/ ./src/

EXPOSE 50051

USER bun

CMD ["bun", "run", "src/server.js"]
