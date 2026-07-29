package benchmark;

import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.micronaut.context.annotation.Value;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.inject.Singleton;

@Singleton
public class CacheService {

    @Value("${redis.host:localhost}")
    private String redisHost;

    @Value("${redis.port:6379}")
    private int redisPort;

    private RedisClient redisClient;
    private StatefulRedisConnection<String, String> connection;

    @PostConstruct
    public void init() {
        redisClient = RedisClient.create("redis://" + redisHost + ":" + redisPort);
        connection = redisClient.connect();
    }

    @PreDestroy
    public void destroy() {
        if (connection != null) {
            connection.close();
        }
        if (redisClient != null) {
            redisClient.shutdown();
        }
    }

    public String checkHealth() {
        try {
            String pong = connection.sync().ping();
            return "PONG".equals(pong) ? "connected" : "error";
        } catch (Exception e) {
            return "error: " + e.getMessage();
        }
    }

    public Models.CacheEntry getCacheEntry(String key) {
        try {
            String value = connection.sync().get(key);
            Long ttl = connection.sync().ttl(key);

            if (value != null) {
                return new Models.CacheEntry(
                        key,
                        value,
                        true,
                        ttl != null ? ttl.intValue() : -1
                );
            }

            String defaultValue = "{\"key\": \"" + key + "\", \"generated\": true}";
            connection.sync().setex(key, 300, defaultValue);

            return new Models.CacheEntry(
                    key,
                    defaultValue,
                    false,
                    300
            );
        } catch (Exception e) {
            String defaultValue = "{\"key\": \"" + key + "\", \"generated\": true}";
            return new Models.CacheEntry(
                    key,
                    defaultValue,
                    false,
                    300
            );
        }
    }
}
