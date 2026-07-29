# Stage 1: Build native executable
FROM ghcr.io/graalvm/native-image-community:21 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn package -Dpackager=native-image -DskipTests -B

# Stage 2: Minimal runtime
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/micronaut-graphql-native-benchmark /app/application

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -sf http://localhost:8080/health || exit 1

ENTRYPOINT ["./application"]
