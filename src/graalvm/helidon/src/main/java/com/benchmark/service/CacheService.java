package com.benchmark.service;

import redis.clients.jedis.JedisPool;

import java.time.Instant;

public class CacheService {
    private final JedisPool jedisPool;

    public CacheService(JedisPool jedisPool) {
        this.jedisPool = jedisPool;
    }

    public CacheResult getOrSet(String key) {
        try (var jedis = jedisPool.getResource()) {
            String value = jedis.get(key);
            if (value != null) {
                return new CacheResult(key, value, true);
            }

            String newValue = "cached-value-" + key + "-" + Instant.now().toEpochMilli();
            jedis.setex(key, 300, newValue);
            return new CacheResult(key, newValue, false);
        } catch (Exception e) {
            throw new RuntimeException("Error in cache operation", e);
        }
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
