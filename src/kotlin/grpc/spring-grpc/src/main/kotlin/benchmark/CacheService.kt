package benchmark

import io.lettuce.core.RedisClient
import io.lettuce.core.api.coroutines
import io.lettuce.core.api.coroutines.RedisCoroutinesCommands
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.stereotype.Service

data class CacheResult(
    val value: String?,
    val hit: Boolean
)

@Service
class CacheService {
    private val redisUrl = System.getenv("REDIS_URL") ?: "redis://localhost:6379"

    private var client: RedisClient? = null
    private var commands: RedisCoroutinesCommands<String, String>? = null

    private suspend fun getCommands(): RedisCoroutinesCommands<String, String> {
        if (commands != null) return commands!!

        client = RedisClient.create(redisUrl)
        val connection = client!!.connect()
        commands = connection.coroutines()
        return commands!!
    }

    suspend fun healthCheck(): String = withContext(Dispatchers.IO) {
        try {
            val cmd = getCommands()
            val result = cmd.ping()
            if (result == "PONG") "connected" else "disconnected"
        } catch (e: Exception) {
            println("Cache health check failed: ${e.message}")
            "disconnected"
        }
    }

    suspend fun get(key: String): CacheResult = withContext(Dispatchers.IO) {
        try {
            val cmd = getCommands()
            val value = cmd.get(key)
            CacheResult(value = value, hit = value != null)
        } catch (e: Exception) {
            println("Cache get error: ${e.message}")
            CacheResult(value = null, hit = false)
        }
    }

    suspend fun set(key: String, value: String, ttlSeconds: Long = 300): Boolean =
        withContext(Dispatchers.IO) {
            try {
                val cmd = getCommands()
                cmd.setex(key, ttlSeconds, value)
                true
            } catch (e: Exception) {
                println("Cache set error: ${e.message}")
                false
            }
        }

    suspend fun close() {
        try {
            client?.shutdown()
        } catch (e: Exception) {
            println("Cache close error: ${e.message}")
        }
    }
}
