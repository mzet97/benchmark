package benchmark

import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.stereotype.Service
import java.util.concurrent.TimeUnit

@Service
class CacheService(private val redisTemplate: StringRedisTemplate) {

    fun checkHealth(): Boolean {
        return try {
            redisTemplate.connectionFactory?.connection?.ping() != null
            true
        } catch (e: Exception) {
            false
        }
    }

    fun get(key: String): String? {
        return redisTemplate.opsForValue().get(key)
    }

    fun set(key: String, value: String, ttlSeconds: Long = 300) {
        redisTemplate.opsForValue().set(key, value, ttlSeconds, TimeUnit.SECONDS)
    }
}
