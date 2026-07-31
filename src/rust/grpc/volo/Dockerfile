FROM rust:1.88-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy proto file (local)
COPY proto/benchmark.proto /app/proto/benchmark.proto

# Copy Rust project
COPY Cargo.toml Cargo.lock ./
COPY build.rs ./
COPY src/ ./src/

RUN cargo build --release --bin server

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/server /usr/local/bin/server

RUN groupadd -r app && useradd -r -g app -u 1001 app
USER app

EXPOSE 50051

CMD ["server"]
