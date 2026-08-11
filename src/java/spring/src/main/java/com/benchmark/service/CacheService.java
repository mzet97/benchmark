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

        // No Thread.sleep(50) on the miss path. It was an invariante 1 violation
        // (docs/ACTION_PLAN.md): hidden work on the measured path. On the
        // kotlin/spring sibling that carried the same sleep, the cache read
        // never hit, so every request paid it and /cache measured 1,962 rps
        // against the 100-connections / 50 ms ceiling of 2,000 -- the number
        // described the delay, not Redis.
        //
        // Even where the read does hit, the measurement window (30 s warmup +
        // 5 x 60 s = 330 s) outlives the 300 s TTL, so the key expires
        // mid-sequence and one repetition eats the stall.
        value = "Cached value for " + key + " at " + Instant.now().toString();
        redisTemplate.opsForValue().set(key, value, Duration.ofSeconds(300));
        return new CacheResult(key, value, false);
    }
}
