FROM ghcr.io/graalvm/graalvm-community:21 AS builder
WORKDIR /app
RUN microdnf install -y maven && microdnf clean all
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

FROM ghcr.io/graalvm/graalvm-community:21
RUN microdnf install -y curl && microdnf clean all
WORKDIR /app
RUN groupadd -r app && useradd -r -g app app
COPY --from=builder /app/target/*.jar app.jar
RUN chown app:app app.jar
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
CMD ["java", "-jar", "app.jar"]
