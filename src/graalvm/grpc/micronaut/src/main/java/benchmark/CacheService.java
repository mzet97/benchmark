package benchmark;

import benchmark.Benchmark.*;
import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.api.sync.RedisCommands;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.time.Instant;

@Singleton
public class CacheService {

    @Inject
    private io.micronaut.context.env.Environment environment;

    private RedisClient redisClient;
    private StatefulRedisConnection<String, String> connection;

    private static final int DEFAULT_TTL = 300;

    @PostConstruct
    void init() {
        String redisUrl = environment.getProperty("redis.url", String.class)
                .orElse("redis://localhost:6379");
        redisClient = RedisClient.create(redisUrl);
        connection = redisClient.connect();
    }

    @PreDestroy
    void destroy() {
        if (connection != null) {
            connection.close();
        }
        if (redisClient != null) {
            redisClient.shutdown();
        }
    }

    public boolean isConnected() {
        try {
            RedisCommands<String, String> commands = connection.sync();
            String pong = commands.ping();
            return "PONG".equals(pong);
        } catch (Exception e) {
            return false;
        }
    }

    public CacheResponse get(String key) {
        try {
            RedisCommands<String, String> commands = connection.sync();
            String value = commands.get(key);

            if (value != null) {
                long ttl = commands.ttl(key);
                return CacheResponse.newBuilder()
                        .setKey(key)
                        .setValue(value)
                        .setCached(true)
                        .setTtl(ttl > 0 ? (int) ttl : DEFAULT_TTL)
                        .setTimestamp(Instant.now().toString())
                        .build();
            }

            // Cache miss - generate and store value
            String generatedValue = "value_" + System.currentTimeMillis();
            commands.setex(key, DEFAULT_TTL, generatedValue);

            return CacheResponse.newBuilder()
                    .setKey(key)
                    .setValue(generatedValue)
                    .setCached(false)
                    .setTtl(DEFAULT_TTL)
                    .setTimestamp(Instant.now().toString())
                    .build();
        } catch (Exception e) {
            return CacheResponse.newBuilder()
                    .setKey(key)
                    .setValue("")
                    .setCached(false)
                    .setTtl(0)
                    .setTimestamp(Instant.now().toString())
                    .build();
        }
    }
}
