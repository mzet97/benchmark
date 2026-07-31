FROM gradle:8.5-jdk21 AS builder

WORKDIR /app

COPY build.gradle.kts settings.gradle.kts ./

RUN gradle dependencies --no-daemon 2>/dev/null || true

COPY src ./src

RUN gradle bootJar --no-daemon

FROM eclipse-temurin:21-jre

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

CMD ["java", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=20", "-jar", "app.jar"]
