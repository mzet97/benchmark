FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install Kitex code generator
RUN go install github.com/cloudwego/kitex/tool/cmd/kitex@latest

WORKDIR /app

# Copy go.mod and go.sum first for caching
COPY src/go/grpc/kitex/go.mod ./
COPY src/go/grpc/kitex/go.sum* ./
RUN go mod tidy || go mod download

# Copy proto contracts
COPY contracts/grpc/ /app/contracts/grpc/

# Generate Kitex code from proto
RUN kitex -module benchmark-kitex -service benchmark -gen-path /app/kitex_gen \
    /app/contracts/grpc/benchmark.proto

# Copy source code
COPY src/go/grpc/kitex/internal/ /app/internal/
COPY src/go/grpc/kitex/cmd/ /app/cmd/

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

EXPOSE 50051

CMD ["server"]
