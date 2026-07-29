FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install protoc plugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.1 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

WORKDIR /app

# Copy go.mod for dependency resolution (skip go.sum to avoid checksum mismatches)
COPY src/go/grpc/grpc-go/go.mod ./
ENV GONOSUMDB=* GONOSUMCHECK=* GOFLAGS=-mod=mod
RUN go mod download

# Copy proto contracts
COPY contracts/grpc/ /app/contracts/grpc/

# Generate proto code
RUN mkdir -p /app/proto/generated && \
    protoc \
      --go_out=/app/proto/generated --go_opt=paths=source_relative \
      --go-grpc_out=/app/proto/generated --go-grpc_opt=paths=source_relative \
      --proto_path=/app/contracts/grpc \
      benchmark.proto

# Copy source code
COPY src/go/grpc/grpc-go/internal/ /app/internal/
COPY src/go/grpc/grpc-go/cmd/ /app/cmd/

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

EXPOSE 50051

CMD ["server"]
