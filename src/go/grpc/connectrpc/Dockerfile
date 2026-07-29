FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install protoc plugins (pin version for Go 1.22 compatibility)
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.1 && \
    go install connectrpc.com/connect/cmd/protoc-gen-connect-go@v1.16.2

WORKDIR /app

# Copy proto contracts
COPY contracts/grpc/ /app/contracts/grpc/

# Copy source code
COPY src/go/grpc/connectrpc/ /app/

# Generate go.sum if missing and download deps
RUN go mod tidy && go mod download

# Generate proto code with ConnectRPC plugin
RUN mkdir -p /app/gen/benchmark && \
    protoc \
      --go_out=/app/gen/benchmark --go_opt=paths=source_relative \
      --connect-go_out=/app/gen/benchmark --connect-go_opt=paths=source_relative \
      --proto_path=/app/contracts/grpc \
      benchmark.proto

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

RUN groupadd --gid 1001 app && useradd --uid 1001 --gid 1001 --shell /bin/false --create-home app

EXPOSE 50051

USER app

CMD ["server"]
