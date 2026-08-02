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
    CMD curl -f http://localhost:8080/health || exit 1

# GC and heap come from JAVA_TOOL_OPTIONS in the ConfigMap, so every JVM
# implementation gets the same collector. The -XX:MaxGCPauseMillis=20 that
# used to be here was tuning only four of them received.
CMD ["java", "-jar", "app.jar"]
