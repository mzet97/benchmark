package com.benchmark.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class CacheService {
    private final RedisTemplate<String, String> redisTemplate;

    @Autowired
    public CacheService(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public CacheResult getOrSet(String key) {
        String value = redisTemplate.opsForValue().get(key);
        if (value != null) {
            return new CacheResult(key, value, true);
        }

        String newValue = "cached-value-" + key + "-" + Instant.now().toEpochMilli();
        redisTemplate.opsForValue().set(key, newValue, java.time.Duration.ofSeconds(300));
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
