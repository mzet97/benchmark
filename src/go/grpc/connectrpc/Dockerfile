FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install protoc plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.1 && \
    go install connectrpc.com/connect/cmd/protoc-gen-connect-go@v1.16.2

WORKDIR /app

# Copy proto file (local to this directory)
COPY proto/ /app/proto/

# Copy source code
COPY . .

# Generate proto code
RUN mkdir -p /app/gen/benchmark && \
    protoc \
      --go_out=/app/gen/benchmark --go_opt=paths=source_relative \
      --connect-go_out=/app/gen/benchmark --connect-go_opt=paths=source_relative \
      --proto_path=/app/proto \
      benchmark.proto

RUN go mod tidy && go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

RUN groupadd -r app && useradd -r -g app -u 1001 app

EXPOSE 50051

USER app

CMD ["server"]
