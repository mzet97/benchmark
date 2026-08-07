# Multi-stage build for Rust Axum
FROM rust:1.95-bookworm AS builder

WORKDIR /app

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./

# Create src directory and dummy main
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies (cached layer)
RUN cargo build --release && rm src/main.rs

# Copy source code
COPY src ./src

# Build application
RUN cargo build --release

# Production stage
FROM debian:bookworm-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r app && useradd -r -g app app

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/target/release/benchmark-axum .

# Switch to non-root user
USER app

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
# Tokio (and Rocket) size their worker pool from the environment, so the
# contract-level BENCH_CPUS drives it without touching the source.
# Shell form so the variable is expanded at runtime.
# See docs/ACTION_PLAN.md, Fase 3.1.
CMD TOKIO_WORKER_THREADS=${BENCH_CPUS:-4} ROCKET_WORKERS=${BENCH_CPUS:-4} ./benchmark-axum
