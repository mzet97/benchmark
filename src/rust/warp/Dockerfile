FROM rust:1.75 AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm src/main.rs
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim AS production
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY --from=builder /app/target/release/benchmark-warp .
USER app
EXPOSE 3000
CMD ["./benchmark-warp"]
