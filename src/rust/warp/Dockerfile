FROM rust:1.95-bookworm AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim AS production
RUN apt-get update && apt-get install -y ca-certificates libssl3 curl && rm -rf /var/lib/apt/lists/*
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY --from=builder /app/target/release/benchmark-warp .
USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -sf http://localhost:8080/health || exit 1

# Tokio (and Rocket) size their worker pool from the environment, so the
# contract-level BENCH_CPUS drives it without touching the source.
# Shell form so the variable is expanded at runtime.
# See docs/ACTION_PLAN.md, Fase 3.1.
CMD TOKIO_WORKER_THREADS=${BENCH_CPUS:-4} ROCKET_WORKERS=${BENCH_CPUS:-4} ./benchmark-warp
