package com.benchmark.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.core.RedisCallback;
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

    /**
     * Goes through RedisTemplate.execute, which borrows a connection from the
     * Lettuce pool and returns it.
     * <p>
     * It used to call {@code getConnectionFactory().getConnection().ping()},
     * which obtains a <em>new</em> connection on every invocation and never
     * closes it. With {@code lettuce.pool.max-active} from the shared ConfigMap,
     * the /health scenario drains the pool within the first few dozen requests
     * and every later caller blocks waiting for one. On the kotlin/spring
     * sibling that carried the identical bug, /health measured 2,910 rps with an
     * 8,018 ms p99, and the exhausted pool then made every cache read in the pod
     * fail as well. See docs/ACTION_PLAN.md, Fase 9.9.
     */
    public boolean ping() {
        try {
            return redisTemplate.execute((RedisCallback<String>) RedisConnection::ping) != null;
        } catch (Exception e) {
            return false;
        }
    }
}
