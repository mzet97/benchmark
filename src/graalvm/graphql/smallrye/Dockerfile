# Stage 1: Build native executable
FROM quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -Dnative -DskipTests -B

# Stage 2: Minimal runtime
FROM quay.io/quarkus/ubi-quarkus-micro-image:2.0
WORKDIR /app

COPY --from=build /app/target/*-runner /app/application

RUN chmod 775 /app

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -sf http://localhost:8080/q/health || exit 1

ENTRYPOINT ["./application", "-Dquarkus.http.host=0.0.0.0"]
