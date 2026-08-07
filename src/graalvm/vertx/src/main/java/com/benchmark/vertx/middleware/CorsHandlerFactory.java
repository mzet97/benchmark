package com.benchmark.vertx.middleware;

import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import io.vertx.ext.web.handler.CorsHandler;

/**
 * CORS middleware handler factory.
 *
 * <p>Named {@code CorsHandlerFactory} rather than {@code CorsHandler} to avoid a
 * name clash with the Vert.x {@link io.vertx.ext.web.handler.CorsHandler} this
 * class builds. The previous code declared a class {@code CorsHandler} that
 * imported {@code CorsHandler}, which is a duplicate-definition compile error.
 */
public final class CorsHandlerFactory {
    private CorsHandlerFactory() {}

    public static Handler<RoutingContext> create(String allowedOriginPattern) {
        return CorsHandler.create(allowedOriginPattern)
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
