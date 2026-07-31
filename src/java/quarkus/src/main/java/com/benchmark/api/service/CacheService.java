package com.benchmark.api.service;

import io.quarkus.redis.datasource.RedisDataSource;
import io.quarkus.redis.datasource.value.ValueCommands;
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
    RedisDataSource redisDataSource;

    private ValueCommands<String, String> valueCommands;

    void init() {
        valueCommands = redisDataSource.value(String.class);
    }

    public Uni<String> get(String key) {
        return Uni.createFrom().item(() -> {
            try {
                if (valueCommands == null) init();
                return valueCommands.get(key);
            } catch (Exception e) {
                LOG.error("Cache get error: {}", e.getMessage());
                return null;
            }
        });
    }

    public Uni<Void> set(String key, String value, Duration ttl) {
        return Uni.createFrom().item(() -> {
            try {
                if (valueCommands == null) init();
                valueCommands.setex(key, ttl.getSeconds(), value);
            } catch (Exception e) {
                LOG.error("Cache set error: {}", e.getMessage());
            }
            return null;
        }).replaceWithVoid();
    }

    public Uni<String> getOrSet(String key, java.util.function.Supplier<String> factory, int ttlSeconds) {
        return get(key).onItem().transformToUni(existing -> {
            if (existing != null) {
                return Uni.createFrom().item(existing);
            }
            String newValue = factory.get();
            return set(key, newValue, Duration.ofSeconds(ttlSeconds)).onItem().transform(v -> newValue);
        });
    }

    public Uni<Boolean> healthCheck() {
        return Uni.createFrom().item(() -> {
            try {
                if (valueCommands == null) init();
                valueCommands.get("__health_check__");
                return true;
            } catch (Exception e) {
                LOG.error("Cache health check error: {}", e.getMessage());
                return false;
            }
        });
    }
}
