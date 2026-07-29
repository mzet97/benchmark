FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml ./
COPY src/ ./src/

RUN mvn clean package -DskipTests --no-transfer-progress

FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -g 1001 -S benchmark && \
    adduser -S benchmark -u 1001 -G benchmark

COPY --from=builder /app/target/*.jar app.jar

USER benchmark

EXPOSE 50051

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD java -cp app.jar benchmark.HealthCheck || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
