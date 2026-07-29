FROM denoland/deno:latest AS builder

WORKDIR /app

COPY deno.json .
COPY *.ts ./

RUN deno cache server.ts

# Production stage
FROM denoland/deno:latest

WORKDIR /app

RUN addgroup --system --gid 1001 denoapp && \
    adduser --system --uid 1001 --gid 1001 denoapp

COPY --from=builder /deno-dir /deno-dir
COPY --from=builder /app /app

USER denoapp

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "server.ts"]
