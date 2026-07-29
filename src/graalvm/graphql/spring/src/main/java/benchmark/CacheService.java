package benchmark;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;

@Service
public class CacheService {

    @Value("${redis.host:localhost}")
    private String redisHost;

    @Value("${redis.port:6379}")
    private int redisPort;

    private JedisPool jedisPool;

    @PostConstruct
    public void init() {
        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxTotal(16);
        poolConfig.setMaxIdle(8);
        jedisPool = new JedisPool(poolConfig, redisHost, redisPort);
    }

    @PreDestroy
    public void destroy() {
        if (jedisPool != null) {
            jedisPool.close();
        }
    }

    public String checkHealth() {
        try (Jedis jedis = jedisPool.getResource()) {
            String pong = jedis.ping();
            return "PONG".equals(pong) ? "connected" : "error";
        } catch (Exception e) {
            return "error: " + e.getMessage();
        }
    }

    public Models.CacheEntry getCacheEntry(String key) {
        try (Jedis jedis = jedisPool.getResource()) {
            String value = jedis.get(key);
            Long ttl = jedis.ttl(key);

            if (value != null) {
                return new Models.CacheEntry(
                        key,
                        value,
                        true,
                        ttl != null ? ttl.intValue() : -1
                );
            }

            String defaultValue = "{\"key\": \"" + key + "\", \"generated\": true}";
            jedis.setex(key, 300, defaultValue);

            return new Models.CacheEntry(
                    key,
                    defaultValue,
                    false,
                    300
            );
        }
    }
}
