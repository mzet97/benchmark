package benchmark

import io.lettuce.core.RedisClient
import io.lettuce.core.api.StatefulRedisConnection
import jakarta.annotation.PostConstruct
import jakarta.annotation.PreDestroy
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service

@Service
class CacheService(
    @Value("\${redis.host:localhost}") private val redisHost: String,
    @Value("\${redis.port:6379}") private val redisPort: Int
) {
    private lateinit var redisClient: RedisClient
    private lateinit var connection: StatefulRedisConnection<String, String>

    @PostConstruct
    fun init() {
        redisClient = RedisClient.create("redis://$redisHost:$redisPort")
        connection = redisClient.connect()
    }

    @PreDestroy
    fun destroy() {
        connection.close()
        redisClient.shutdown()
    }

    fun checkHealth(): Boolean {
        return try {
            val pong = connection.sync().ping()
            "PONG" == pong
        } catch (e: Exception) {
            false
        }
    }

    fun get(key: String): String? {
        return try {
            connection.sync().get(key)
        } catch (e: Exception) {
            null
        }
    }

    fun set(key: String, value: String, ttlSeconds: Long) {
        try {
            connection.sync().setex(key, ttlSeconds, value)
        } catch (e: Exception) {
            // ignore
        }
    }

    fun ttl(key: String): Long {
        return try {
            connection.sync().ttl(key)
        } catch (e: Exception) {
            -2
        }
    }
}
