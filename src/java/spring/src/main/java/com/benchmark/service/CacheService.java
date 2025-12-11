package com.benchmark.service;

import com.benchmark.model.CacheResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
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

        try {
            Thread.sleep(50);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        value = "Cached value for " + key + " at " + Instant.now().toString();
        redisTemplate.opsForValue().set(key, value, Duration.ofSeconds(300));
        return new CacheResult(key, value, false);
    }
}
