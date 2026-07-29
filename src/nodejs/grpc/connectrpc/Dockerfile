FROM node:18-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

FROM node:18-alpine

WORKDIR /app

RUN addgroup -g 1001 -S benchmark && \
    adduser -S benchmark -u 1001 -G benchmark

COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY proto/ ./proto/
COPY src/ ./src/

USER benchmark

EXPOSE 50051

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:50051/healthz || exit 1

CMD ["node", "src/server.js"]
