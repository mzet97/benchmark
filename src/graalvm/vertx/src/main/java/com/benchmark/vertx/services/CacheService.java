package com.benchmark.vertx.services;

import com.benchmark.vertx.config.Config;
import io.vertx.core.Future;
import io.vertx.core.Promise;
import io.vertx.core.Vertx;
import io.vertx.redis.client.Command;
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
        this(config, Vertx.vertx());
    }

    public CacheService(Config config, Vertx vertx) {
        this.config = config;

        // RedisOptions in Vert.x 4 has no setPort/setPassword; configuration is
        // done with a single connection string. Redis.createClient also needs
        // the Vertx instance it will run on.
        URI redisUri = URI.create(config.getRedisUrl());

        // Rebuild a redis://[user:pass@]host:port[/db] endpoint. The input URL
        // from the contract is already in this form, so use it directly when it
        // carries the scheme; otherwise reconstruct host:port.
        String endpoint = config.getRedisUrl();
        if (endpoint == null || endpoint.isEmpty()) {
            String host = redisUri.getHost();
            int port = redisUri.getPort();
            if (port == -1) {
                port = 6379;
            }
            endpoint = "redis://" + host + ":" + port;
        }

        RedisOptions options = new RedisOptions()
            .setConnectionString(endpoint);

        // Create Redis client
        redis = Redis.createClient(vertx, options);
    }

    public Future<String> get(String key) {
        Promise<String> promise = Promise.promise();

        redis.send(Request.cmd(Command.GET).arg(key))
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

        redis.send(Request.cmd(Command.SETEX)
            .arg(key)
            .arg(String.valueOf(ttl))
            .arg(value))
            .onSuccess(response -> promise.complete())
            .onFailure(promise::fail);

        return promise.future();
    }

    public Future<Boolean> ping() {
        Promise<Boolean> promise = Promise.promise();

        redis.send(Request.cmd(Command.PING))
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
