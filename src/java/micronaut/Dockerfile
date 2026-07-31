FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -B
# List what was built for debugging
RUN ls -la target/*.jar && echo "===" && jar tf target/*.jar | grep -i manifest | head -5

FROM eclipse-temurin:21-jre
WORKDIR /app

# Create non-root user
RUN groupadd -r app && useradd -r -g app app

# Copy the full target dir with deps
COPY --from=builder --chown=app:app /app/target/ ./target/

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8080/health || exit 1

# Use classpath with all dependency jars
CMD ["java", "-cp", "target/benchmark-micronaut-1.0.0.jar:target/dependency/*", "com.benchmark.Application"]
