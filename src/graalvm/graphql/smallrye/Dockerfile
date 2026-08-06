# Stage 1: Build native executable
FROM quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -Dnative -DskipTests -B -Dquarkus.native.additional-build-args="--gc=G1"

# Stage 2: Minimal runtime
FROM quay.io/quarkus/ubi-quarkus-micro-image:2.0
WORKDIR /app

COPY --from=build /app/target/*-runner /app/application

RUN chmod 775 /app

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -sf http://localhost:8080/q/health || exit 1

# A GraalVM native executable does not read JAVA_TOOL_OPTIONS, so the heap
# settings every JVM implementation gets from the ConfigMap have to be passed
# here. -Xms/-Xmx are documented runtime options for native images; without
# them this binary sizes its heap from the container's memory on its own,
# against 8g everywhere else. See docs/ACTION_PLAN.md, Fase 3.1.
ENTRYPOINT ["./application", "-Xms8g", "-Xmx8g", "-Dquarkus.http.host=0.0.0.0"]
