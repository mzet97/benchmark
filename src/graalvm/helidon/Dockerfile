# Stage 1: Build with GraalVM
FROM ghcr.io/graalvm/graalvm-community:21 AS builder
WORKDIR /build
# Install Maven
RUN microdnf install -y maven && microdnf clean all

# Cache dependencies first for better layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests -B

# Stage 2: Runtime with GraalVM JDK
FROM ghcr.io/graalvm/graalvm-community:21 AS runtime

WORKDIR /app

# Create non-root user
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/false --create-home appuser

# Copy JAR from builder
COPY --from=builder /build/target/benchmark-helidon-1.0.0.jar /app/app.jar

# Set ownership
RUN chown -R appuser:appuser /app

USER 1001

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
