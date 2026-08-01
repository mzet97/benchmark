package com.benchmark.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.*;

/**
 * Contract regression test for the canonical /json payload.
 * See contracts/rest/canonical-payloads.md.
 */
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
            .body("items[0].uuid", is("00000000-0000-0000-0000-000000000000"))
            .body("items[0].name", is("Item 0"))
            .body("items[0].email", is("item0@benchmark.local"))
            .body("items[0].createdAt", is("2026-01-01T00:00:00Z"))
            .body("items[0].isActive", is(true))
            .body("items[999].id", is(999))
            .body("items[999].uuid", is("00000000-0000-0000-0000-000000000999"))
            .body("items[999].name", is("Item 999"))
            .body("items[999].isActive", is(false));
    }

    @Test
    public void testJsonEndpointHonoursN() {
        given()
            .when().get("/json?n=100")
            .then()
            .statusCode(200)
            .body("items.size()", is(100))
            .body("count", is(100));
    }

    @Test
    public void testJsonEndpointFallsBackOnGarbage() {
        given()
            .when().get("/json?n=abc")
            .then()
            .statusCode(200)
            .body("count", is(1000));
    }
}
