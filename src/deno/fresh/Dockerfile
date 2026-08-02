FROM denoland/deno:2.0 AS builder
WORKDIR /app
COPY deno.json .
COPY . .
RUN deno cache server.ts

FROM denoland/deno:2.0-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
RUN groupadd --system --gid 1001 denoapp && useradd --system --uid 1001 --gid 1001 denoapp
WORKDIR /app
COPY --from=builder /deno-dir /deno-dir
COPY --chown=denoapp:denoapp . .
USER denoapp
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
# index.ts forks BENCH_CPUS workers, which needs --allow-run for
# Deno.execPath(). The workers themselves keep the original permissions.
CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "--allow-run", "index.ts"]
