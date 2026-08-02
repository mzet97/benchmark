# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests -B

# Stage 2: Runtime
FROM eclipse-temurin:21-jre
WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8080/actuator/health || exit 1

# GC and heap come from JAVA_TOOL_OPTIONS in the ConfigMap, so every JVM
# implementation gets the same collector. The -XX:MaxGCPauseMillis=20 that
# used to be here was tuning only four of them received.
ENTRYPOINT ["java", "-jar", "app.jar"]
