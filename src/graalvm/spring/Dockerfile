# Stage 1: Build with GraalVM
FROM ghcr.io/graalvm/graalvm-community:21 AS builder
WORKDIR /build

# Install Maven
RUN microdnf install -y maven && microdnf clean all

# Cache dependencies first for better layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build native image.
#
# The Spring Boot parent's `native` profile only binds `process-aot`
# (spring-boot-maven-plugin) and `add-reachability-metadata`
# (native-maven-plugin) to the lifecycle; it does NOT bind `native:compile`.
# So `mvn package -Pnative` alone produced no binary in target/ and the
# runtime stage failed with
#   "/build/target/benchmark-graalvm-spring": not found
# The `native:compile` goal must be invoked explicitly. It is run *after*
# `package` so AOT processing and reachability metadata are already on disk.
#
# `-DbuildArgs=--gc=G1` is the native-maven-plugin's user property for passing
# GraalVM builder arguments (the property is literally `buildArgs`, confirmed
# against CompileMojo's @parameter). The previous `-Dspring.native.buildargs`
# is not a real property of any plugin here, so it was a silent no-op -- G1
# was never actually selected. G1 is supported in GraalVM native-image on
# JDK 21 (see GraalVM JDK 21 release notes). The shared ConfigMap pins every
# JVM implementation to G1 (-XX:+UseG1GC), so the native image matches it.
COPY src ./src
RUN mvn -Pnative -DskipTests -B package native:compile -DbuildArgs=--gc=G1

# Stage 2: Minimal runtime
FROM debian:bookworm-slim AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN groupadd --gid 1001 appuser && \
    useradd --uid 1001 --gid 1001 --shell /bin/false --create-home appuser

# Copy native binary from builder
COPY --from=builder /build/target/benchmark-graalvm-spring /app/app
RUN chmod +x /app/app

# Set ownership
RUN chown -R appuser:appuser /app

USER 1001

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# A GraalVM native executable does not read JAVA_TOOL_OPTIONS, so the heap
# settings every JVM implementation gets from the ConfigMap have to be passed
# here. -Xms/-Xmx are documented runtime options for native images; without
# them this binary sizes its heap from the container's memory on its own,
# against 8g everywhere else. See docs/ACTION_PLAN.md, Fase 3.1.
ENTRYPOINT ["./app", "-Xms8g", "-Xmx8g"]
