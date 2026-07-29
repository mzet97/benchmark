FROM denoland/deno:latest

WORKDIR /app

# Cache dependencies
COPY deno.json ./
RUN deno install || true

# Copy source
COPY proto/ ./proto/
COPY *.ts ./

# Cache the entry point
RUN deno cache server.ts

EXPOSE 50051

USER deno

CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "server.ts"]
