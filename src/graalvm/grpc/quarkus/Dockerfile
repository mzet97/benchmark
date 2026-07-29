## Stage 1 : build with maven
FROM quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 AS build
COPY --chown=quarkus:quarkus pom.xml /code/pom.xml
COPY --chown=quarkus:quarkus mvnw /code/mvnw
COPY --chown=quarkus:quarkus .mvn /code/.mvn
USER quarkus
WORKDIR /code
RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.6.1:go-offline
COPY src /code/src
RUN ./mvnw package -Dnative -DskipTests

## Stage 2 : create the runtime image
FROM quay.io/quarkus/quarkus-micro-image:2.0
WORKDIR /work/
RUN chown 1001 /work \
    && chmod "g+rwX" /work \
    && chown 1001:root /work
COPY --from=build /code/target/*-runner /work/application

EXPOSE 50051

USER 1001

CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
