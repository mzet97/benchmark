FROM denoland/deno:latest AS builder

WORKDIR /app
COPY deno.json .
COPY . .

# Cache dependencies as root
RUN deno install server.ts 2>/dev/null || true
RUN deno cache server.ts 2>/dev/null || true

# Runtime
FROM denoland/deno:latest

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Create user before setting up cache
RUN groupadd --system --gid 1001 denoapp && useradd --system --uid 1001 --gid 1001 denoapp

WORKDIR /app

# Copy cached deps from builder
COPY --from=builder /deno-dir /deno-dir
RUN chown -R denoapp:denoapp /deno-dir

# Copy app
COPY --chown=denoapp:denoapp . .

# Cache again as the app user to fix permissions
RUN deno cache server.ts 2>/dev/null || true

USER denoapp
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "server.ts"]
