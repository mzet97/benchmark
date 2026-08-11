package com.benchmark.service

import org.springframework.data.redis.core.RedisCallback
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

    /// Goes through RedisTemplate.execute, which borrows a connection from the
    /// Lettuce pool and returns it.
    ///
    /// It used to call `redisTemplate.connectionFactory.connection.ping()`, which
    /// obtains a *new* connection on every invocation and never closes it. With
    /// `spring.data.redis.lettuce.pool.max-active=32` from the ConfigMap, the
    /// /health scenario drained the pool within the first few dozen requests and
    /// every later caller blocked waiting for one: /health measured 2,910 rps
    /// with an 8,018 ms p99.
    ///
    /// The damage did not stop at /health. Once the pool was exhausted, every
    /// cache read in the same pod failed too, so getOrSet always took the miss
    /// branch -- which is why /cache sat at 1,962 rps against the
    /// 100-connections / 50 ms ceiling of the Thread.sleep(50) that used to live
    /// in CacheController. One leak explained both numbers.
    fun ping(): Boolean {
        return try {
            redisTemplate.execute(RedisCallback { it.ping() }) == "PONG"
        } catch (e: Exception) {
            false
        }
    }
}
