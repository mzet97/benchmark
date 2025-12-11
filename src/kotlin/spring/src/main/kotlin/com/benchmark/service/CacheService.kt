package com.benchmark.service

import org.springframework.data.redis.core.RedisTemplate
import org.springframework.stereotype.Service
import java.time.Duration

@Service
class CacheService(
    private val redisTemplate: RedisTemplate<String, String>
) {
    fun get(key: String): String? {
        return redisTemplate.opsForValue().get(key)
    }

    fun set(key: String, value: String, ttlSeconds: Int = 300): Boolean {
        return try {
            redisTemplate.opsForValue().set(key, value, Duration.ofSeconds(ttlSeconds.toLong()))
            true
        } catch (e: Exception) {
            println("Error setting cache key $key: ${e.message}")
            false
        }
    }

    fun getOrSet(key: String, factory: () -> String, ttlSeconds: Int = 300): Pair<String, Boolean> {
        return try {
            val existing = get(key)
            if (existing != null) {
                Pair(existing, true)
            } else {
                val value = factory()
                set(key, value, ttlSeconds)
                Pair(value, false)
            }
        } catch (e: Exception) {
            println("Error in getOrSet for key $key: ${e.message}")
            Pair(factory(), false)
        }
    }

    fun ping(): Boolean {
        return try {
            val result = redisTemplate.getConnectionFactory().connection.ping()
            result == "PONG"
        } catch (e: Exception) {
            println("Cache health check failed: ${e.message}")
            false
        }
    }
}
