FROM denoland/deno:latest AS builder

WORKDIR /app

COPY deno.json .
COPY *.ts ./

RUN deno cache server.ts

# Production stage
FROM denoland/deno:latest

WORKDIR /app

RUN groupadd -r denoapp && useradd -r -g denoapp -u 1001 denoapp

COPY --from=builder /deno-dir /deno-dir
COPY --from=builder /app /app

USER denoapp

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# index.ts forks BENCH_CPUS workers, which needs --allow-run for
# Deno.execPath(). The workers themselves keep the original permissions.
CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "--allow-run", "index.ts"]
