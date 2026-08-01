package com.benchmark.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.TimeUnit;

@Service
public class CacheService {
    private final RedisTemplate<String, String> redisTemplate;
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Autowired
    public CacheService(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    // The TTL is part of the response contract and must match what the
    // endpoint reports. See contracts/rest/canonical-payloads.md.
    public static final int CACHE_TTL_SECONDS = 300;

    /** The value plus whether it came from Redis. */
    public record CacheHit(String value, boolean cached) {
    }

    public String getOrSet(String key) {
        return getOrSetWithSource(key).value();
    }

    public CacheHit getOrSetWithSource(String key) {
        String value = redisTemplate.opsForValue().get(key);
        if (value != null) {
            return new CacheHit(value, true);
        }

        String newValue = "cached-value-" + key + "-" + LocalDateTime.now().format(formatter);
        redisTemplate.opsForValue().set(key, newValue, CACHE_TTL_SECONDS, TimeUnit.SECONDS);
        return new CacheHit(newValue, false);
    }

    public boolean ping() {
        try {
            return redisTemplate.getConnectionFactory().getConnection().ping() != null;
        } catch (Exception e) {
            return false;
        }
    }
}
