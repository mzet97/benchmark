package com.benchmark.vertx.middleware;

import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Request logging middleware.
 */
public class LoggingHandler implements Handler<RoutingContext> {
    private static final Logger logger = LoggerFactory.getLogger(LoggingHandler.class);

    private LoggingHandler() {}

    public static Handler<RoutingContext> create() {
        return new LoggingHandler();
    }

    @Override
    public void handle(RoutingContext ctx) {
        long startTime = System.currentTimeMillis();

        ctx.addBodyEndHandler(v -> {
            long duration = System.currentTimeMillis() - startTime;

            logger.info("Request processed - Method: {}, URL: {}, Status: {}, Duration: {}ms",
                ctx.request().method(),
                ctx.request().uri(),
                ctx.response().getStatusCode(),
                duration);
        });

        ctx.next();
    }
}
