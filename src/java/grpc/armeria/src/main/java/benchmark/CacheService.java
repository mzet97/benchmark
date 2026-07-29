package benchmark;

import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

public class CacheService {

    private final JedisPool jedisPool;

    public CacheService() {
        String redisUrl = System.getenv().getOrDefault("REDIS_URL", "redis://localhost:6379");
        // Parse redis://host:port
        String host = "localhost";
        int port = 6379;
        if (redisUrl.startsWith("redis://")) {
            String withoutProtocol = redisUrl.substring("redis://".length());
            String[] parts = withoutProtocol.split(":");
            if (parts.length >= 1) host = parts[0];
            if (parts.length >= 2) port = Integer.parseInt(parts[1].split("/")[0]);
        }

        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxTotal(10);
        poolConfig.setMaxIdle(5);
        poolConfig.setMinIdle(1);

        this.jedisPool = new JedisPool(poolConfig, host, port);
    }

    public String healthCheck() {
        try (Jedis jedis = jedisPool.getResource()) {
            String result = jedis.ping();
            return "PONG".equals(result) ? "connected" : "disconnected";
        } catch (Exception e) {
            System.err.println("Cache health check failed: " + e.getMessage());
            return "disconnected";
        }
    }

    public CacheResult get(String key) {
        try (Jedis jedis = jedisPool.getResource()) {
            String value = jedis.get(key);
            return new CacheResult(value, value != null);
        } catch (Exception e) {
            System.err.println("Cache get error: " + e.getMessage());
            return new CacheResult(null, false);
        }
    }

    public boolean set(String key, String value, int ttlSeconds) {
        try (Jedis jedis = jedisPool.getResource()) {
            jedis.setex(key, ttlSeconds, value);
            return true;
        } catch (Exception e) {
            System.err.println("Cache set error: " + e.getMessage());
            return false;
        }
    }

    public void close() {
        try {
            jedisPool.close();
        } catch (Exception e) {
            System.err.println("Cache close error: " + e.getMessage());
        }
    }

    public static class CacheResult {
        private final String value;
        private final boolean hit;

        public CacheResult(String value, boolean hit) {
            this.value = value;
            this.hit = hit;
        }

        public String getValue() { return value; }
        public boolean isHit() { return hit; }
    }
}
