package benchmark;

import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

public class CacheService {

    private final JedisPool pool;

    public CacheService() {
        String host = System.getenv().getOrDefault("REDIS_HOST", "localhost");
        int port = Integer.parseInt(System.getenv().getOrDefault("REDIS_PORT", "6379"));
        String password = System.getenv().getOrDefault("REDIS_PASSWORD", "");
        int db = Integer.parseInt(System.getenv().getOrDefault("REDIS_DB", "0"));

        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxTotal(20);
        poolConfig.setMaxIdle(10);
        poolConfig.setMinIdle(2);

        if (password != null && !password.isEmpty()) {
            this.pool = new JedisPool(poolConfig, host, port, 5000, password, db);
        } else {
            this.pool = new JedisPool(poolConfig, host, port, 5000, null, db);
        }
    }

    public String checkHealth() {
        try (Jedis jedis = pool.getResource()) {
            jedis.ping();
            return "connected";
        } catch (Exception e) {
            return "disconnected";
        }
    }

    public CacheResult getValue(String key) {
        try (Jedis jedis = pool.getResource()) {
            String value = jedis.get(key);
            if (value != null) {
                long ttl = jedis.ttl(key);
                return new CacheResult(value, true, ttl > 0 ? (int) ttl : 0);
            }

            // Cache miss: generate a value, store it, return
            String generatedValue = "generated_value_" + key + "_" + System.currentTimeMillis();
            jedis.setex(key, 3600, generatedValue);
            return new CacheResult(generatedValue, false, 3600);
        }
    }

    public void close() {
        pool.close();
    }

    public static class CacheResult {
        public final String value;
        public final boolean cached;
        public final int ttl;

        public CacheResult(String value, boolean cached, int ttl) {
            this.value = value;
            this.cached = cached;
            this.ttl = ttl;
        }
    }
}
