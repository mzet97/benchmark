FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install Kitex code generator
RUN go install github.com/cloudwego/kitex/tool/cmd/kitex@latest

WORKDIR /app

# Copy proto contracts
COPY contracts/grpc/ /app/contracts/grpc/

# Copy source code
COPY src/go/grpc/kitex/ /app/

# Generate go.sum if missing and download deps
RUN go mod tidy && go mod download

# Generate Kitex code from proto
RUN kitex -module benchmark-kitex -service benchmark -gen-path /app/kitex_gen \
    /app/contracts/grpc/benchmark.proto

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

RUN groupadd --gid 1001 app && useradd --uid 1001 --gid 1001 --shell /bin/false --create-home app

EXPOSE 50051

USER app

CMD ["server"]
