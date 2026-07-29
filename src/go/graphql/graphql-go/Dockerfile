FROM golang:1.22-bookworm AS builder
WORKDIR /app
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /server .

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /server /usr/local/bin/server
ENV PORT=8080
RUN groupadd --gid 1001 app && useradd --uid 1001 --gid 1001 --shell /bin/false --create-home app
EXPOSE 8080
USER app
CMD ["server"]
