package com.benchmark.services

import io.lettuce.core.RedisClient
import io.lettuce.core.api.StatefulRedisConnection
import io.lettuce.core.api.sync.RedisCommands
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.time.Duration

class CacheService {
    private val redisClient: RedisClient
    private val connection: StatefulRedisConnection<String, String>

    init {
        val redisUrl = System.getenv("REDIS_URL") ?: "redis://:Admin@123@redis.home.arpa:30379"
        redisClient = RedisClient.create(redisUrl)
        connection = redisClient.connect()
    }

    suspend fun get(key: String): String? = withContext(Dispatchers.IO) {
        try {
            val syncCommands: RedisCommands<String, String> = connection.sync()
            syncCommands.get(key)
        } catch (e: Exception) {
            null
        }
    }

    suspend fun set(key: String, value: String, ttlSeconds: Long) = withContext(Dispatchers.IO) {
        try {
            val syncCommands: RedisCommands<String, String> = connection.sync()
            syncCommands.setex(key, ttlSeconds, value)
        } catch (e: Exception) {
            // Log error in real application
        }
    }

    suspend fun getOrSet(key: String, newValue: String, ttlSeconds: Long = 300): String = withContext(Dispatchers.IO) {
        val existing = get(key)
        if (existing != null) {
            existing
        } else {
            set(key, newValue, ttlSeconds)
            newValue
        }
    }

    suspend fun healthCheck(): Boolean = withContext(Dispatchers.IO) {
        try {
            val syncCommands: RedisCommands<String, String> = connection.sync()
            val result = syncCommands.ping()
            result == "PONG"
        } catch (e: Exception) {
            false
        }
    }

    fun close() {
        connection.close()
        redisClient.shutdown()
    }
}
