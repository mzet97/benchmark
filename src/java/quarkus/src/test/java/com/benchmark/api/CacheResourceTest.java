package com.benchmark.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.*;

@QuarkusTest
public class CacheResourceTest {

    @Test
    public void testCacheEndpoint() {
        String key = "test-" + System.currentTimeMillis();

        given()
            .when().get("/cache?key=" + key)
            .then()
            .statusCode(200)
            .body("key", is(key))
            .body("value", is(notNullValue()))
            .body("cached", is(false))
            .body("ttl", is(300))
            .body("timestamp", is(notNullValue()));
    }

    @Test
    public void testCacheEndpointWithoutKey() {
        given()
            .when().get("/cache")
            .then()
            .statusCode(200)
            .body("key", is("test"))
            .body("value", is(notNullValue()))
            .body("timestamp", is(notNullValue()));
    }
}
