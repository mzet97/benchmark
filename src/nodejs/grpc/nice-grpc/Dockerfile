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

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "const grpc=require('@grpc/grpc-js');const c=new grpc.Client('localhost:8080',grpc.credentials.createInsecure());c.getChannel().getConnectivityState(true)===2?process.exit(0):process.exit(1)" || exit 1

CMD ["node", "src/index.js"]
