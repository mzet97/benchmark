package com.benchmark.service;

import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.api.sync.RedisCommands;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Singleton
public class CacheService {
    private final RedisClient redisClient;
    private final StatefulRedisConnection connection;
    private final RedisCommands<String, String> commands;

    @Inject
    public CacheService(RedisClient redisClient) {
        this.redisClient = redisClient;
        this.connection = redisClient.connect();
        this.commands = connection.sync();
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
        String value = commands.get(key);
        if (value != null) {
            return new CacheHit(value, true);
        }

        String newValue = "cached-value-" + key + "-" + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        commands.setex(key, CACHE_TTL_SECONDS, newValue);
        return new CacheHit(newValue, false);
    }

    public boolean ping() {
        try {
            String result = commands.ping();
            return "PONG".equals(result);
        } catch (Exception e) {
            return false;
        }
    }

    public void close() {
        connection.close();
        redisClient.shutdown();
    }
}
