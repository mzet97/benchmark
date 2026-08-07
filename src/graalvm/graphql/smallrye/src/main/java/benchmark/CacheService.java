package benchmark;

import io.quarkus.redis.datasource.RedisDataSource;
import io.quarkus.redis.datasource.keys.KeyCommands;
import io.quarkus.redis.datasource.value.ValueCommands;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.time.Duration;

@ApplicationScoped
public class CacheService {

    @Inject
    RedisDataSource redisDataSource;

    public String checkHealth() {
        try {
            var commands = redisDataSource.value(String.class);
            commands.set("health:check", "ok");
            String result = commands.get("health:check");
            return "ok".equals(result) ? "connected" : "error";
        } catch (Exception e) {
            return "error: " + e.getMessage();
        }
    }

    public Models.CacheEntry getCacheEntry(String key) {
        ValueCommands<String, String> commands = redisDataSource.value(String.class);
        KeyCommands<String> keyCommands = redisDataSource.key();

        String value = commands.get(key);
        if (value != null) {
            long ttl;
            try {
                ttl = keyCommands.ttl(key);
            } catch (io.quarkus.redis.datasource.keys.RedisKeyNotFoundException e) {
                ttl = -1;
            }
            return new Models.CacheEntry(
                    key,
                    value,
                    true,
                    (int) ttl
            );
        }

        // Generate a default value and cache it
        String defaultValue = "{\"key\": \"" + key + "\", \"generated\": true}";
        commands.set(key, defaultValue);
        keyCommands.expire(key, Duration.ofSeconds(300));

        return new Models.CacheEntry(
                key,
                defaultValue,
                false,
                300
        );
    }
}
