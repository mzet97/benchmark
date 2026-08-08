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
#
# Heap override: the shared ConfigMap sets JAVA_TOOL_OPTIONS with
# `-Xms32g -Xmx32g` for the JVM implementations. That heap is sized for the
# full-server JVM stacks (Spring/Micronaut/Quarkus) which run as -jar apps;
# this Vert.x launch is a plain `java -cp` and reserving 32 GiB at startup
# pushes the 40 GiB container into OOMKill during the JVM's initial commit.
# Explicit `-Xms4g -Xmx4g` on the command line wins over JAVA_TOOL_OPTIONS
# (last-wins for the same flag), keeping the GC/processor-count tuning while
# capping the heap to a value the container survives. This is NOT a native
# image, so it does read JAVA_TOOL_OPTIONS and does need the override.
ENTRYPOINT ["java", "-Xms4g", "-Xmx4g", "-cp", "app.jar:lib/*", "com.benchmark.vertx.Main"]
