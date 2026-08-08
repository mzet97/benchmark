package com.benchmark.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;

@QuarkusTest
public class HealthResourceTest {

    @Test
    public void testHealthEndpoint() {
        given()
            .when().get("/health")
            .then()
            .statusCode(200)
            .body("status", is(notNullValue()))
            .body("database", is(notNullValue()))
            .body("cache", is(notNullValue()))
            .body("timestamp", is(notNullValue()));
    }
}
