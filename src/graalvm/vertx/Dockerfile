# Multi-stage build for GraalVM Vert.x application
FROM ghcr.io/graalvm/graalvm-community:21 AS builder

# Set working directory
WORKDIR /app

# Install Maven
RUN yum install -y maven

# Copy pom.xml
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build JAR
RUN mvn clean package -DskipTests

# Production stage
FROM ghcr.io/graalvm/graalvm-community:21 AS production

# Install curl for health checks
RUN yum install -y curl && yum clean all

# Set working directory
WORKDIR /app

# Create app user
RUN groupadd -r app && useradd -r -g app app

# Copy pom.xml
COPY pom.xml .

# Install only runtime dependencies
RUN mvn dependency:resolve -B

# Copy JAR from builder
COPY --from=builder /app/target/*.jar app.jar

# Switch to non-root user
USER app

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Run the application
CMD ["java", "-jar", "app.jar"]
