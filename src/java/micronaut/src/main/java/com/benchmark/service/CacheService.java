package com.benchmark.service;

import com.benchmark.model.CacheResult;
import io.lettuce.core.api.StatefulRedisConnection;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.time.Instant;

@Singleton
public class CacheService {
    private final StatefulRedisConnection<String, String> redisConnection;

    @Inject
    public CacheService(StatefulRedisConnection<String, String> redisConnection) {
        this.redisConnection = redisConnection;
    }

    public CacheResult getOrSet(String key) {
        String value = redisConnection.sync().get(key);
        if (value != null) {
            return new CacheResult(key, value, true);
        }

        value = "cached-value-" + key + "-" + System.currentTimeMillis();
        redisConnection.sync().setex(key, 300, value);
        return new CacheResult(key, value, false);
    }
}
