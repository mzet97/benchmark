package com.benchmark.vertx.services;

import com.benchmark.vertx.config.Config;
import io.vertx.core.Future;
import io.vertx.core.Promise;
import io.vertx.redis.client.Redis;
import io.vertx.redis.client.RedisOptions;
import io.vertx.redis.client.Request;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;

/**
 * Cache service for Redis operations.
 */
public class CacheService {
    private static final Logger logger = LoggerFactory.getLogger(CacheService.class);

    private final Config config;
    private final Redis redis;

    public CacheService(Config config) {
        this.config = config;

        // Parse Redis URL
        URI redisUri = URI.create(config.getRedisUrl());

        // Create Redis options
        RedisOptions options = new RedisOptions()
            .setEndpoint(redisUri.getHost())
            .setPort(redisUri.getPort());

        if (redisUri.getUserInfo() != null && !redisUri.getUserInfo().isEmpty()) {
            options.setPassword(redisUri.getUserInfo().split(":")[1]);
        }

        // Create Redis client
        redis = Redis.createClient(options);
    }

    public Future<String> get(String key) {
        Promise<String> promise = Promise.promise();

        redis.send(Request.cmd(Request.Command.GET).arg(key))
            .onSuccess(response -> {
                if (response != null) {
                    promise.complete(response.toString());
                } else {
                    promise.complete(null);
                }
            })
            .onFailure(promise::fail);

        return promise.future();
    }

    public Future<Void> set(String key, String value, int ttl) {
        Promise<Void> promise = Promise.promise();

        redis.send(Request.cmd(Request.Command.SETEX)
            .arg(key)
            .arg(String.valueOf(ttl))
            .arg(value))
            .onSuccess(response -> promise.complete())
            .onFailure(promise::fail);

        return promise.future();
    }

    public Future<Boolean> ping() {
        Promise<Boolean> promise = Promise.promise();

        redis.send(Request.cmd(Request.Command.PING))
            .onSuccess(response -> promise.complete(true))
            .onFailure(err -> {
                logger.error("Redis health check failed", err);
                promise.complete(false);
            });

        return promise.future();
    }

    public void close() {
        redis.close();
    }
}
