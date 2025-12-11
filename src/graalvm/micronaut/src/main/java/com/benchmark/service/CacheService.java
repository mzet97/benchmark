package com.benchmark.service;

import jakarta.inject.Inject;
import jakarta.inject.Singleton;
import io.lettuce.core.api.StatefulRedisConnection;

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

        String newValue = "cached-value-" + key + "-" + Instant.now().toEpochMilli();
        redisConnection.sync().setex(key, 300, newValue);
        return new CacheResult(key, newValue, false);
    }

    public static class CacheResult {
        private final String key;
        private final String value;
        private final boolean cached;

        public CacheResult(String key, String value, boolean cached) {
            this.key = key;
            this.value = value;
            this.cached = cached;
        }

        public String getKey() {
            return key;
        }

        public String getValue() {
            return value;
        }

        public boolean isCached() {
            return cached;
        }
    }
}
