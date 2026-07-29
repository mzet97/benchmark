# Stage 1: Build dependencies (cached layer)
FROM rust:1.82-bookworm AS deps
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# Stage 2: Build application
FROM rust:1.82-bookworm AS builder
WORKDIR /app
COPY --from=deps /app/target target
COPY --from=deps /app/Cargo.toml ./
COPY --from=deps /app/Cargo.lock ./
COPY src ./src
RUN touch src/main.rs && cargo build --release

# Stage 3: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/*
RUN groupadd --gid 1001 app && useradd --uid 1001 --gid 1001 --shell /bin/false --create-home app
WORKDIR /app
COPY --from=builder /app/target/release/benchmark-actix ./main
RUN chown app:app ./main
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
CMD ["./main"]
