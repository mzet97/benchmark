FROM ghcr.io/graalvm/graalvm-community:21 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -Pnative

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/target/*-linux-amd64 .
EXPOSE 3000
CMD ["./app"]
