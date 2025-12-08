package com.benchmark.vertx.middleware;

import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.CorsHandler;

/**
 * CORS middleware handler.
 */
public class CorsHandler {
    private CorsHandler() {}

    public static Handler<RoutingContext> create(String allowedOriginPattern) {
        return io.vertx.ext.web.handler.CorsHandler.create(allowedOriginPattern)
            .allowedMethod(io.vertx.core.http.HttpMethod.GET)
            .allowedMethod(io.vertx.core.http.HttpMethod.POST)
            .allowedMethod(io.vertx.core.http.HttpMethod.PUT)
            .allowedMethod(io.vertx.core.http.HttpMethod.DELETE)
            .allowedMethod(io.vertx.core.http.HttpMethod.OPTIONS)
            .allowedHeader("Content-Type")
            .allowedHeader("Authorization")
            .allowedHeader("Access-Control-Request-Method")
            .allowedHeader("Access-Control-Request-Headers");
    }
}
