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

    public String getOrSet(String key) {
        String value = commands.get(key);
        if (value != null) {
            return value;
        }

        String newValue = "cached-value-" + key + "-" + LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        commands.setex(key, 300, newValue);
        return newValue;
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
