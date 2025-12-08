# Multi-stage Dockerfile for Kotlin Ktor
# Stage 1: Build
FROM gradle:8.10-jdk21 AS builder

# Set working directory
WORKDIR /app

# Copy gradle files
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .

# Copy source code
COPY src ./src

# Build application (fat JAR)
RUN gradle build --no-daemon

# Stage 2: Runtime
FROM openjdk:21-jdk-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# Set working directory
WORKDIR /app

# Copy JAR from builder
COPY --from=builder /app/build/libs/benchmark-ktor.jar ./

# Change ownership
RUN chown -R appuser:appgroup /app
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run application
CMD ["java", "-XX:+UseG1GC", "-Xms128m", "-Xmx512m", "-jar", "benchmark-ktor.jar"]
