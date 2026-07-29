FROM rust:1.88-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy proto contracts first
COPY contracts/grpc/ /app/contracts/grpc/

# Copy Rust project
COPY src/rust/grpc/volo/Cargo.toml /app/
COPY src/rust/grpc/volo/build.rs /app/
COPY src/rust/grpc/volo/src/ /app/src/

RUN cargo build --release --bin server

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/server /usr/local/bin/server

EXPOSE 50051

CMD ["server"]
