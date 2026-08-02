package com.benchmark

import io.lettuce.core.RedisClient
import io.lettuce.core.RedisURI
import io.lettuce.core.api.StatefulRedisConnection

/**
 * Redis access for the http4k implementation.
 *
 * /cache used to answer 200 with a fabricated hit while this project declared
 * no Redis dependency at all. See docs/ACTION_PLAN.md, Fase 3.
 *
 * Lettuce multiplexes commands from every thread over one connection, which is
 * how src/kotlin/ktor uses it too.
 */
class Cache {
    private var client: RedisClient? = null
    private var connection: StatefulRedisConnection<String, String>? = null
    private val available: Boolean

    init {
        var ok = false
        try {
            val redisUrl = System.getenv("REDIS_URL") ?: error("REDIS_URL is required")

            // Parse redis://:password@host:port, splitting at the last @ so a
            // password containing one still parses.
            val afterScheme = redisUrl.substringAfter("://")
            val lastAt = afterScheme.lastIndexOf('@')
            val password = afterScheme.substring(1, lastAt) // skip the leading ':'
            val hostPort = afterScheme.substring(lastAt + 1)
            val host = hostPort.substringBefore(':')
            val port = hostPort.substringAfter(':').toIntOrNull() ?: 6379

            val uri = RedisURI.Builder.redis(host, port)
                .withPassword(password.toCharArray())
                .build()

            client = RedisClient.create(uri)
            connection = client!!.connect()
            ok = true
        } catch (e: Exception) {
            System.err.println("Warning: Redis connection failed, cache disabled: ${e.message}")
        }
        available = ok
    }

    fun get(key: String): String? = try {
        if (available) connection!!.sync().get(key) else null
    } catch (e: Exception) {
        null
    }

    fun set(key: String, value: String, ttlSeconds: Long) {
        try {
            if (available) connection!!.sync().setex(key, ttlSeconds, value)
        } catch (e: Exception) {
            // A cache write failure must not turn into a 500: the other
            // implementations degrade the same way.
        }
    }

    fun healthy(): Boolean = try {
        available && connection!!.sync().ping() == "PONG"
    } catch (e: Exception) {
        false
    }

    fun close() {
        try {
            connection?.close()
            client?.shutdown()
        } catch (_: Exception) {
        }
    }
}
