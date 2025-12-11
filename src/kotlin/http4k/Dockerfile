FROM eclipse-temurin:21-jdk AS builder
WORKDIR /app
COPY build.gradle .
RUN ./gradlew build || true
COPY src ./src
RUN ./gradlew build

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
