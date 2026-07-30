FROM gradle:8.5-jdk21 AS builder
WORKDIR /app
COPY build.gradle .
RUN gradle dependencies --no-daemon
COPY src ./src
RUN gradle build

FROM eclipse-temurin:21-jre
WORKDIR /app

# Create non-root user
RUN groupadd -r app && useradd -r -g app app

COPY --from=builder --chown=app:app /app/build/libs/*.jar app.jar

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

USER app
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8080/actuator/health || exit 1

CMD ["java", "-jar", "app.jar"]
