package benchmark;

import dev.benchmark.grpc.Benchmark.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

import java.time.Instant;

public class CacheService {

    private static final Logger logger = LoggerFactory.getLogger(CacheService.class);
    private static final int DEFAULT_TTL = 300;

    private final JedisPool jedisPool;

    public CacheService() {
        String redisUrl = System.getenv().getOrDefault("REDIS_URL", "redis://localhost:6379");

        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxTotal(25);
        poolConfig.setMaxIdle(10);
        poolConfig.setMinIdle(5);

        this.jedisPool = new JedisPool(poolConfig, redisUrl);
        logger.info("Redis connection pool initialized");
    }

    public boolean isConnected() {
        try (Jedis jedis = jedisPool.getResource()) {
            String pong = jedis.ping();
            return "PONG".equals(pong);
        } catch (Exception e) {
            return false;
        }
    }

    public CacheResponse get(String key) {
        try (Jedis jedis = jedisPool.getResource()) {
            String value = jedis.get(key);

            if (value != null) {
                long ttl = jedis.ttl(key);
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
            jedis.setex(key, DEFAULT_TTL, generatedValue);

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

    public void close() {
        if (jedisPool != null && !jedisPool.isClosed()) {
            jedisPool.close();
            logger.info("Redis connection pool closed");
        }
    }
}
