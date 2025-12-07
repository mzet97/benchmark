# Multi-stage Dockerfile for .NET 9 Native AOT
# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS builder

WORKDIR /src

# Install Native AOT prerequisites (clang, zlib)
RUN apt-get update && apt-get install -y \
    clang \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy project file and restore dependencies
COPY *.csproj ./
RUN dotnet restore benchmark-api.csproj

# Copy source code
COPY . .

# Publish with Native AOT
RUN dotnet publish benchmark-api.csproj \
    -c Release \
    -o /app/publish \
    -p:PublishAot=true \
    -p:InvariantGlobalization=true

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/runtime-deps:9.0

WORKDIR /app

# Install runtime dependencies for Native AOT
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libicu72 \
    && rm -rf /var/lib/apt/lists/*

# Copy published application
COPY --from=builder /app/publish .

# Create non-root user
RUN addgroup --system --gid 1001 dotnet && \
    adduser --system --uid 1001 --gid 1001 --shell /bin/false dotnet

# Set ownership
RUN chown -R dotnet:dotnet /app
USER dotnet

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
ENTRYPOINT ["./benchmark-api"]
