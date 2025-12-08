package com.benchmark.vertx.handlers;

import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import io.vertx.core.json.JsonArray;
import io.vertx.core.json.JsonObject;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;

/**
 * JSON response endpoint handler.
 */
public class JsonHandler implements Handler<RoutingContext> {
    private JsonHandler() {}

    public static Handler<RoutingContext> create() {
        return new JsonHandler();
    }

    @Override
    public void handle(RoutingContext ctx) {
        JsonArray items = new JsonArray();

        ZonedDateTime now = ZonedDateTime.now(ZoneOffset.UTC);

        for (int i = 0; i < 1000; i++) {
            JsonObject item = new JsonObject();
            item.put("id", i + 1);
            item.put("name", "Item " + (i + 1));
            item.put("value", "Value " + (i + 1));
            item.put("timestamp", now.toInstant().toString());
            items.add(item);
        }

        ctx.response()
            .putHeader("Content-Type", "application/json")
            .end(items.encode());
    }
}
