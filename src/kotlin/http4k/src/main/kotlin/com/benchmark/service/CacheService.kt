package com.benchmark.service

import redis.clients.jedis.Jedis
import java.time.Instant

class CacheService {
    private var jedis: Jedis? = null

    fun init() {
        try {
            val redisUrl = System.getenv("REDIS_URL") ?: "redis://:Admin@123@redis.home.arpa:30379"
            jedis = Jedis(redisUrl)
            jedis?.ping()
            println("✅ Redis connection established")
        } catch (e: Exception) {
            println("❌ Failed to connect to Redis: ${e.message}")
            throw e
        }
    }

    fun get(key: String): String? {
        return try {
            jedis?.get(key)
        } catch (e: Exception) {
            println("Error getting cache key $key: ${e.message}")
            null
        }
    }

    fun set(key: String, value: String, ttlSeconds: Int = 300): Boolean {
        return try {
            jedis?.setex(key, ttlSeconds, value) ?: false
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
            val result = jedis?.ping()
            result == "PONG"
        } catch (e: Exception) {
            println("Cache health check failed: ${e.message}")
            false
        }
    }

    fun close() {
        jedis?.close()
        jedis = null
        println("✅ Redis connection closed")
    }
}
