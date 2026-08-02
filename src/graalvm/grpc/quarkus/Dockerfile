## Stage 1 : build with maven
FROM quay.io/quarkus/ubi-quarkus-mandrel-builder-image:jdk-21 AS build
COPY --chown=quarkus:quarkus pom.xml /code/pom.xml
USER quarkus
WORKDIR /code
RUN mvn -B org.apache.maven.plugins:maven-dependency-plugin:3.6.1:go-offline
COPY src /code/src
RUN mvn package -Dnative -DskipTests

## Stage 2 : create the runtime image
FROM quay.io/quarkus/quarkus-micro-image:2.0
WORKDIR /work/
RUN chown 1001 /work \
    && chmod "g+rwX" /work \
    && chown 1001:root /work
COPY --from=build /code/target/*-runner /work/application

EXPOSE 8080

USER 1001

# A GraalVM native executable does not read JAVA_TOOL_OPTIONS, so the heap
# settings every JVM implementation gets from the ConfigMap have to be passed
# here. -Xms/-Xmx are documented runtime options for native images; without
# them this binary sizes its heap from the container's memory on its own,
# against 8g everywhere else. See docs/ACTION_PLAN.md, Fase 3.1.
CMD ["./application", "-Xms8g", "-Xmx8g", "-Dquarkus.http.host=0.0.0.0"]
