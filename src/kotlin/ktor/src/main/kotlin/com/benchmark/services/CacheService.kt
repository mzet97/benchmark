package com.benchmark.services

import io.lettuce.core.RedisClient
import io.lettuce.core.RedisURI
import io.lettuce.core.api.StatefulRedisConnection
import io.lettuce.core.api.sync.RedisCommands
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class CacheService {
    private var redisClient: RedisClient? = null
    private var connection: StatefulRedisConnection<String, String>? = null
    private val available: Boolean

    init {
        var ok = false
        try {
            val redisUrl = System.getenv("REDIS_URL") ?: error("REDIS_URL is required")

            // Parse redis://:password@host:port (handle @ in password)
            val afterScheme = redisUrl.substringAfter("://")
            val lastAt = afterScheme.lastIndexOf('@')
            val password = afterScheme.substring(1, lastAt) // skip leading ':'
            val hostPort = afterScheme.substring(lastAt + 1)
            val host = hostPort.substringBefore(':')
            val port = hostPort.substringAfter(':').toIntOrNull() ?: 6379

            val redisUri = RedisURI.Builder.redis(host, port)
                .withPassword(password.toCharArray())
                .build()

            redisClient = RedisClient.create(redisUri)
            connection = redisClient!!.connect()
            ok = true
        } catch (e: Exception) {
            System.err.println("Warning: Redis connection failed, cache disabled: ${e.message}")
        }
        available = ok
    }

    suspend fun get(key: String): String? = withContext(Dispatchers.IO) {
        try {
            if (!available) return@withContext null
            val syncCommands: RedisCommands<String, String> = connection!!.sync()
            syncCommands.get(key)
        } catch (e: Exception) { null }
    }

    suspend fun set(key: String, value: String, ttlSeconds: Long) = withContext(Dispatchers.IO) {
        try {
            if (!available) return@withContext
            val syncCommands: RedisCommands<String, String> = connection!!.sync()
            syncCommands.setex(key, ttlSeconds, value)
        } catch (e: Exception) { }
    }

    suspend fun getOrSet(key: String, newValue: String, ttlSeconds: Long = 300): String = withContext(Dispatchers.IO) {
        val existing = get(key)
        if (existing != null) existing else { set(key, newValue, ttlSeconds); newValue }
    }

    suspend fun healthCheck(): Boolean = withContext(Dispatchers.IO) {
        try {
            if (!available) return@withContext false
            val syncCommands: RedisCommands<String, String> = connection!!.sync()
            syncCommands.ping() == "PONG"
        } catch (e: Exception) { false }
    }

    fun close() {
        try {
            connection?.close()
            redisClient?.shutdown()
        } catch (_: Exception) {}
    }
}
