package com.benchmark.vertx.handlers;

import com.benchmark.vertx.Canonical;

import io.vertx.core.Handler;
import io.vertx.core.json.JsonObject;
import io.vertx.ext.web.RoutingContext;

/**
 * JSON response endpoint handler.
 *
 * <p>The previous implementation returned a bare array with no envelope,
 * numbered items from 1, emitted {id,name,value,timestamp}, and ignored ?n=.
 * See contracts/rest/canonical-payloads.md.
 */
public class JsonHandler implements Handler<RoutingContext> {
    private JsonHandler() {}

    public static Handler<RoutingContext> create() {
        return new JsonHandler();
    }

    @Override
    public void handle(RoutingContext ctx) {
        JsonObject response = new JsonObject(Canonical.response(ctx.request().getParam("n")));

        ctx.response()
            .putHeader("Content-Type", "application/json")
            .end(response.encode());
    }
}
