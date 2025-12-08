# Multi-stage Dockerfile for Quarkus Native Image
# Stage 1: Build Native Image
FROM quay.io/quarkus/ubi-quarkus-mandrel:23.1-java21 AS builder

# Set working directory
WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src ./src

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Build Native Image
RUN mvn -B -DskipTests package -Pnative -Dquarkus.native.container-build=true

# Stage 2: Runtime Image
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libcicm1tbb2 \
    libnss3 \
    libnspr4 \
    libdbus-1-3 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -r -s /bin/false quarkus

# Set working directory
WORKDIR /app

# Copy native binary from builder
COPY --from=builder /app/target/*-runner ./

# Change ownership
RUN chown -R quarkus:quarkus /app
USER quarkus

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Set JVM options for native image
ENV JAVA_OPTS="-Xmx64m"

# Run the native image
CMD ["./application-1.0.0-runner"]
