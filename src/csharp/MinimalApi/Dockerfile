# Multi-stage Dockerfile for .NET 9 with Native AOT
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS builder

# Install AOT prerequisites
RUN apt-get update && apt-get install -y \
    clang \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY *.csproj ./
RUN dotnet restore benchmark-api.csproj

COPY . .
# Publish with Native AOT
RUN dotnet publish benchmark-api.csproj -c Release -o /app/publish -r linux-x64

# Runtime - minimal base since AOT produces native binary
FROM debian:bookworm-slim

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/publish/benchmark-api .

RUN groupadd -r dotnet && useradd -r -g dotnet -u 1001 dotnet
RUN chown -R dotnet:dotnet /app
USER dotnet

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["./benchmark-api"]
