# Stage 1: Build with GraalVM
FROM ghcr.io/graalvm/graalvm-community:21 AS builder
WORKDIR /build

# Cache dependencies first for better layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build native image
COPY src ./src
RUN mvn package -Pnative -DskipTests -B

# Stage 2: Minimal runtime
FROM debian:bookworm-slim AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/false --create-home appuser

# Copy native binary from builder
COPY --from=builder /build/target/benchmark-graalvm-spring /app/app
RUN chmod +x /app/app

# Set ownership
RUN chown -R appuser:appuser /app

USER 1001

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["./app"]
