package com.benchmark.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.*;

@QuarkusTest
public class JsonResourceTest {

    @Test
    public void testJsonEndpoint() {
        given()
            .when().get("/json")
            .then()
            .statusCode(200)
            .body("items.size()", is(1000))
            .body("count", is(1000))
            .body("timestamp", is(notNullValue()))
            .body("items[0].id", is(0))
            .body("items[0].name", is("Item 0"))
            .body("items[999].id", is(999))
            .body("items[999].name", is("Item 999"));
    }
}
