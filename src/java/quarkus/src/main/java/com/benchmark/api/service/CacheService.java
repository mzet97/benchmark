package com.benchmark.api.service;

import io.quarkus.redis.client.RedisClient;
import io.smallrye.mutiny.Uni;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;

@ApplicationScoped
public class CacheService {

    private static final Logger LOG = LoggerFactory.getLogger(CacheService.class);

    @Inject
    RedisClient redisClient;

    public Uni<String> get(String key) {
        return redisClient.get(key)
                .map(response -> response != null ? response.toString() : null)
                .onFailure().recoverWithItem(t -> {
                    LOG.error("Cache get error for key {}: {}", key, t.getMessage());
                    return null;
                });
    }

    public Uni<Void> set(String key, String value, Duration ttl) {
        return redisClient.setex(key, (int) ttl.getSeconds(), value)
                .map(response -> null)
                .onFailure().recoverWithItem(t -> {
                    LOG.error("Cache set error for key {}: {}", key, t.getMessage());
                    return null;
                });
    }

    public Uni<String> getOrSet(String key, String newValue, Duration ttl) {
        return get(key)
                .onItem().ifNull().switchTo(() -> {
                    LOG.info("Cache miss for key: {}", key);
                    return set(key, newValue, ttl)
                            .map(v -> newValue);
                })
                .onItem().ifNotNull().invoke(value -> {
                    LOG.info("Cache hit for key: {}", key);
                });
    }

    public Uni<Boolean> healthCheck() {
        return redisClient.ping()
                .map(response -> response != null)
                .onFailure().recoverWithItem(false);
    }
}
