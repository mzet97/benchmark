# The build step used to be a bare `javac` of Main.java with no classpath. That
# only worked because Main was a com.sun.net.httpserver server with no
# dependencies; building the real Vert.x application needs Maven, like every
# other JVM implementation here. See docs/ACTION_PLAN.md, Fase 3.
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -DskipTests -B
RUN mvn dependency:copy-dependencies -DincludeScope=runtime -DoutputDirectory=target/dependency

FROM eclipse-temurin:21-jre
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app

RUN groupadd -r app && useradd -r -g app app

COPY --from=builder /build/target/*.jar /app/app.jar
COPY --from=builder /build/target/dependency/ /app/lib/

RUN chown -R app:app /app
USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# -cp rather than -jar: the jar plugin writes a Main-Class but no Class-Path, so
# the dependencies have to be named explicitly.
ENTRYPOINT ["java", "-cp", "app.jar:lib/*", "com.benchmark.vertx.Main"]
