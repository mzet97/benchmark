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

# Pin the UID/GID to 1001. The base deployment template
# (deploy/k3s/base/deployment.yaml) sets runAsUser/runAsGroup: 1001 at the pod
# level, so whatever user the image declares is overridden in the cluster.
# Earlier this created `app` with an arbitrary system UID (useradd -r with no
# -u): under k8s the container then ran as UID 1001 against files owned by a
# different UID, the entrypoint could not be reliably resolved/executed, the
# pod stayed Running 0/1 and `kubectl logs` was empty. The sibling JVM images
# (helidon, micronaut) pin -u 1001 for the same reason.
RUN groupadd -r -g 1001 app && useradd -r -u 1001 -g 1001 app

COPY --from=builder /build/target/*.jar /app/app.jar
COPY --from=builder /build/target/dependency/ /app/lib/

# -cp rather than -jar: the jar plugin writes a Main-Class but no Class-Path, so
# the dependencies have to be named explicitly.
#
# Heap override: the shared ConfigMap sets JAVA_TOOL_OPTIONS to
# "-XX:ActiveProcessorCount=40 -Xms32g -Xmx32g -XX:+UseG1GC". 32g of heap in a
# 40 GiB container (with a native metaspace + direct buffers for Vert.x's
# Netty) leaves no room and the JVM spends the measurement window thrashing the
# GC, which is what made every endpoint time out.
#
# JAVA_TOOL_OPTIONS is read by the JVM *before* main() and applied on top of any
# command-line flags, so a plain `java -Xmx4g ...` still ends up at 32g. An
# `ENV JAVA_TOOL_OPTIONS=""` in the image is overridden again by the ConfigMap's
# envFrom. The only reliable override is to drop the variable in a wrapper
# before exec'ing java, then pass the flags we actually want on the command
# line. `exec` replaces the shell so the JVM receives SIGTERM directly.
#
# The wrapper is written while still root (before USER app) and chowned to the
# app user, so it is present, owned by 1001, and executable regardless of which
# UID k8s runs the container as. Generating it with printf inside a RUN that
# ran *after* USER app produced a file owned by the image's build-time user; at
# runtime, under a different UID, the exec could silently fail and leave the
# pod with empty logs.
RUN printf '%s\n' \
    '#!/bin/sh' \
    'unset JAVA_TOOL_OPTIONS' \
    'CPUS="${BENCH_CPUS:-4}"' \
    'exec java -Xms4g -Xmx4g -XX:ActiveProcessorCount="$CPUS" -XX:+UseG1GC -cp app.jar:lib/* com.benchmark.vertx.Main "$@"' \
    > /app/run.sh && chmod +x /app/run.sh

RUN chown -R app:app /app

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/run.sh"]
