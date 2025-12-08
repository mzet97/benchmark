package com.benchmark.vertx.handlers;

import com.benchmark.vertx.config.Config;
import com.benchmark.vertx.services.CacheService;
import io.vertx.core.Handler;
import io.vertx.ext.web.RoutingContext;
import io.vertx.redis.client.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Cache endpoint handler.
 */
public class CacheHandler implements Handler<RoutingContext> {
    private static final Logger logger = LoggerFactory.getLogger(CacheHandler.class);

    private final Config config;
    private final CacheService cacheService;

    private CacheHandler(Config config) {
        this.config = config;
        this.cacheService = new CacheService(config);
    }

    public static Handler<RoutingContext> create(Config config) {
        return new CacheHandler(config);
    }

    @Override
    public void handle(RoutingContext ctx) {
        String key = ctx.request().getParam("key");

        if (key == null) {
            ctx.response()
                .setStatusCode(400)
                .putHeader("Content-Type", "application/json")
                .end(new io.vertx.core.json.JsonObject()
                    .put("error", "Bad Request")
                    .put("message", "key parameter is required")
                    .encode());
            return;
        }

        int ttl = config.getCacheTtl();

        // Try to get from cache
        cacheService.get(key)
            .onSuccess(cachedValue -> {
                if (cachedValue != null) {
                    io.vertx.core.json.JsonObject response = new io.vertx.core.json.JsonObject();
                    response.put("key", key);
                    response.put("value", cachedValue);
                    response.put("cached", true);
                    response.put("ttl", ttl);

                    ctx.response()
                        .putHeader("Content-Type", "application/json")
                        .end(response.encode());
                } else {
                    // Generate new value
                    String value = "cached_data_" + key + "_" + System.currentTimeMillis();

                    // Store in cache
                    cacheService.set(key, value, ttl)
                        .onSuccess(v -> {
                            io.vertx.core.json.JsonObject response = new io.vertx.core.json.JsonObject();
                            response.put("key", key);
                            response.put("value", value);
                            response.put("cached", false);
                            response.put("ttl", ttl);

                            ctx.response()
                                .putHeader("Content-Type", "application/json")
                                .end(response.encode());
                        })
                        .onFailure(err -> {
                            logger.error("Failed to set cache", err);
                            ctx.response()
                                .setStatusCode(500)
                                .putHeader("Content-Type", "application/json")
                                .end(new io.vertx.core.json.JsonObject()
                                    .put("error", "Internal Server Error")
                                    .put("message", "Failed to set cache")
                                    .encode());
                        });
                }
            })
            .onFailure(err -> {
                logger.error("Failed to get cache", err);
                ctx.response()
                    .setStatusCode(500)
                    .putHeader("Content-Type", "application/json")
                    .end(new io.vertx.core.json.JsonObject()
                        .put("error", "Internal Server Error")
                        .put("message", "Failed to get cache")
                        .encode());
            });
    }
}
