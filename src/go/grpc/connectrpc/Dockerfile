FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install protoc plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.1 && \
    go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest

WORKDIR /app

# Copy go.mod and go.sum first for caching
COPY src/go/grpc/connectrpc/go.mod src/go/grpc/connectrpc/go.sum ./
RUN go mod download

# Copy proto contracts
COPY contracts/grpc/ /app/contracts/grpc/

# Generate proto code with ConnectRPC plugin
RUN mkdir -p /app/gen/benchmark && \
    protoc \
      --go_out=/app/gen/benchmark --go_opt=paths=source_relative \
      --connect-go_out=/app/gen/benchmark --connect-go_opt=paths=source_relative \
      --proto_path=/app/contracts/grpc \
      benchmark.proto

# Copy source code
COPY src/go/grpc/connectrpc/internal/ /app/internal/
COPY src/go/grpc/connectrpc/cmd/ /app/cmd/

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

EXPOSE 50051

CMD ["server"]
