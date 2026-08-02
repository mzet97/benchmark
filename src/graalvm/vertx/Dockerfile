FROM ghcr.io/graalvm/graalvm-community:21 AS builder
WORKDIR /app
COPY src ./src
RUN mkdir -p out && javac -d out src/main/java/com/benchmark/vertx/Main.java

FROM ghcr.io/graalvm/graalvm-community:21
RUN microdnf install -y curl && microdnf clean all
WORKDIR /app
RUN groupadd -r app && useradd -r -g app app
COPY --from=builder /app/out ./out
RUN chown -R app:app /app
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
CMD ["java", "-cp", "out", "com.benchmark.vertx.Main"]
