FROM rust:latest AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/*
RUN useradd -r -s /bin/false appuser
WORKDIR /app
COPY --from=builder /app/target/release/benchmark-actix ./main
RUN chown appuser:appuser ./main
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
CMD ["./main"]
