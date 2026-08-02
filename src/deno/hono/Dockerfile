FROM denoland/deno:latest

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
RUN groupadd --system --gid 1001 denoapp && useradd --system --uid 1001 --gid 1001 denoapp

WORKDIR /app
COPY --chown=denoapp:denoapp . .

RUN deno install server.ts 2>/dev/null || true

USER denoapp
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "server.ts"]
