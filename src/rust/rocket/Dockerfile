FROM rust:1.95-bookworm AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm src/main.rs

COPY src ./src
COPY .env* ./

RUN cargo build --release

FROM debian:bookworm-slim AS production

RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*

RUN groupadd -r app && useradd -r -g app app

WORKDIR /app

COPY --from=builder /app/target/release/benchmark-rocket .

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Tokio (and Rocket) size their worker pool from the environment, so the
# contract-level BENCH_CPUS drives it without touching the source.
# ROCKET_PORT/ROCKET_ADDRESS are set explicitly: Rocket 0.5 defaults to
# 127.0.0.1:8000, but the readiness probe checks TCP 8080 and the container
# must listen on 0.0.0.0.
# Shell form so the variables are expanded at runtime.
# See docs/ACTION_PLAN.md, Fase 3.1.
CMD TOKIO_WORKER_THREADS=${BENCH_CPUS:-4} \
    ROCKET_WORKERS=${BENCH_CPUS:-4} \
    ROCKET_ADDRESS=0.0.0.0 \
    ROCKET_PORT=${PORT:-8080} \
    ./benchmark-rocket
