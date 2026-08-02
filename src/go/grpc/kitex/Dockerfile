FROM golang:1.22-bookworm AS builder

RUN apt-get update && apt-get install -y protobuf-compiler && rm -rf /var/lib/apt/lists/*

# Install Kitex code generator
RUN go install github.com/cloudwego/kitex/tool/cmd/kitex@latest

WORKDIR /app

# Copy proto file (local to this directory)
COPY proto/ /app/proto/

# Copy source code
COPY . .

# Generate Kitex code from proto
RUN kitex -module benchmark-kitex -service benchmark -gen-path /app/kitex_gen \
    /app/proto/benchmark.proto

RUN go mod tidy && go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server/

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/server /usr/local/bin/server

RUN groupadd -r app && useradd -r -g app -u 1001 app

EXPOSE 8080

USER app

CMD ["server"]
