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

    public String getOrSet(String key) {
        String value = redisTemplate.opsForValue().get(key);
        if (value != null) {
            return value;
        }

        String newValue = "cached-value-" + key + "-" + LocalDateTime.now().format(formatter);
        redisTemplate.opsForValue().set(key, newValue, 300, TimeUnit.SECONDS);
        return newValue;
    }

    public boolean ping() {
        try {
            return redisTemplate.getConnectionFactory().getConnection().ping() != null;
        } catch (Exception e) {
            return false;
        }
    }
}
