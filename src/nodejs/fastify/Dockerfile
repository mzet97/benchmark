# Multi-stage Dockerfile for Node.js Fastify
FROM node:22-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install --force
COPY . .

FROM node:22-alpine

RUN apk add --no-cache ca-certificates curl
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app .
USER nodejs

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["node", "src/index.js"]
