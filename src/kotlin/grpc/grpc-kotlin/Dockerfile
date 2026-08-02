FROM gradle:8.5-jdk17 AS builder

WORKDIR /app

COPY build.gradle.kts settings.gradle.kts ./
COPY src/ ./src/

RUN gradle jar --no-daemon

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -g 1001 -S benchmark && \
    adduser -S benchmark -u 1001 -G benchmark

COPY --from=builder /app/build/libs/*.jar app.jar

USER benchmark

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD nc -z localhost 50051 || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
