package benchmark;

import io.quarkus.redis.datasource.RedisDataSource;
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

        String value = commands.get(key);
        if (value != null) {
            Long ttl = commands.ttl(key);
            return new Models.CacheEntry(
                    key,
                    value,
                    true,
                    ttl != null ? ttl.intValue() : -1
            );
        }

        // Generate a default value and cache it
        String defaultValue = "{\"key\": \"" + key + "\", \"generated\": true}";
        commands.set(key, defaultValue);
        commands.expire(key, Duration.ofSeconds(300));

        return new Models.CacheEntry(
                key,
                defaultValue,
                false,
                300
        );
    }
}
