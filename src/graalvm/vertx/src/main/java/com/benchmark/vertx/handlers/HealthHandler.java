package com.benchmark.vertx.handlers;

import com.benchmark.vertx.config.Config;
import com.benchmark.vertx.services.DatabaseService;
import com.benchmark.vertx.services.CacheService;
import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZoneOffset;
import java.time.ZonedDateTime;

/**
 * Health check endpoint handler.
 */
public class HealthHandler implements Handler<RoutingContext> {
    private static final Logger logger = LoggerFactory.getLogger(HealthHandler.class);

    private final Config config;
    private final DatabaseService databaseService;
    private final CacheService cacheService;

    private HealthHandler(Config config) {
        this.config = config;
        this.databaseService = new DatabaseService(config);
        this.cacheService = new CacheService(config);
    }

    public static Handler<RoutingContext> create(Config config) {
        return new HealthHandler(config);
    }

    public static Handler<RoutingContext> createHealthz() {
        return ctx -> {
            ctx.response()
                .putHeader("Content-Type", "application/json")
                .end(new io.vertx.core.json.JsonObject()
                    .put("status", "ok")
                    .encode());
        };
    }

    @Override
    public void handle(RoutingContext ctx) {
        databaseService.healthCheck()
            .compose(dbHealthy -> {
                return cacheService.ping()
                    .map(cacheHealthy -> {
                        io.vertx.core.json.JsonObject health = new io.vertx.core.json.JsonObject();
                        health.put("status", dbHealthy && cacheHealthy ? "healthy" : "unhealthy");
                        health.put("version", "1.0.0");
                        health.put("timestamp", ZonedDateTime.now(ZoneOffset.UTC).toInstant().toString());
                        health.put("database", dbHealthy ? "healthy" : "unhealthy");
                        health.put("cache", cacheHealthy ? "healthy" : "unhealthy");

                        int statusCode = (dbHealthy && cacheHealthy) ? 200 : 503;
                        ctx.response()
                            .setStatusCode(statusCode)
                            .putHeader("Content-Type", "application/json")
                            .end(health.encode());

                        return null;
                    });
            })
            .onFailure(err -> {
                logger.error("Health check failed", err);
                ctx.response()
                    .setStatusCode(503)
                    .putHeader("Content-Type", "application/json")
                    .end(new io.vertx.core.json.JsonObject()
                        .put("status", "unhealthy")
                        .put("error", err.getMessage())
                        .encode());
            });
    }
}
