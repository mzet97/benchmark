package com.benchmark.vertx.middleware;

import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Global error handler middleware.
 */
public class ErrorHandler implements Handler<RoutingContext> {
    private static final Logger logger = LoggerFactory.getLogger(ErrorHandler.class);

    private ErrorHandler() {}

    public static Handler<RoutingContext> create() {
        return new ErrorHandler();
    }

    @Override
    public void handle(RoutingContext ctx) {
        ctx.response().exceptionHandler(error -> {
            logger.error("Unhandled error", error);
        });

        ctx.next();
    }
}
