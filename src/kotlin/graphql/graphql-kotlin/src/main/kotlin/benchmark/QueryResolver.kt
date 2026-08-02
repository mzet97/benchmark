package benchmark

import com.expediagroup.graphql.server.operations.Query
import org.springframework.stereotype.Component
import java.time.Instant
import java.util.*

@Component
class QueryResolver(
    private val databaseService: DatabaseService,
    private val cacheService: CacheService
) : Query {

    fun health(): Health {
        val dbOk = databaseService.checkHealth()
        val cacheOk = cacheService.checkHealth()
        return Health(
            status = "ok",
            version = "1.0.0",
            timestamp = Instant.now().toString(),
            database = if (dbOk) "connected" else "disconnected",
            cache = if (cacheOk) "connected" else "disconnected"
        )
    }

    fun jsonItems(limit: Int = 1000): JsonItemsResult {
        val now = Instant.now().toString()
        val count = Canonical.itemCount(limit)
        val items = (0 until count).map { i ->
            JsonItem(
                id = i,
                uuid = Canonical.uuid(i),
                name = Canonical.name(i),
                email = Canonical.email(i),
                createdAt = Canonical.CREATED_AT,
                isActive = Canonical.isActive(i)
            )
        }
        return JsonItemsResult(
            items = items,
            count = items.size,
            timestamp = now
        )
    }

    fun user(id: Int): User? {
        return databaseService.getUser(id)
    }

    fun complexOrders(days: Int = 30): ComplexOrdersResult {
        val data = databaseService.getComplexOrders(days)
        return ComplexOrdersResult(
            periodDays = days,
            totalUsers = data.size,
            data = data
        )
    }

    fun cache(key: String): CacheEntry {
        val cached = cacheService.get(key)
        if (cached != null) {
            val ttl = cacheService.ttl(key)
            return CacheEntry(
                key = key,
                value = cached,
                cached = true,
                ttl = if (ttl >= 0) ttl.toInt() else 0
            )
        }
        val value = """{"key": "$key", "generated": true}"""
        cacheService.set(key, value, 300)
        return CacheEntry(
            key = key,
            value = value,
            cached = false,
            ttl = 300
        )
    }
}

data class Health(
    val status: String,
    val version: String,
    val timestamp: String,
    val database: String,
    val cache: String
)

data class JsonItem(
    val id: Int,
    val uuid: String,
    val name: String,
    val email: String,
    val createdAt: String,
    val isActive: Boolean
)

data class JsonItemsResult(
    val items: List<JsonItem>,
    val count: Int,
    val timestamp: String
)

data class User(
    val id: Int,
    val email: String,
    val firstName: String,
    val lastName: String,
    val age: Int,
    val createdAt: String
)

data class UserOrderStats(
    val userId: Int,
    val userName: String,
    val totalOrders: Int,
    val totalValue: Double,
    val averageOrderValue: Double
)

data class ComplexOrdersResult(
    val periodDays: Int,
    val totalUsers: Int,
    val data: List<UserOrderStats>
)

data class CacheEntry(
    val key: String,
    val value: String,
    val cached: Boolean,
    val ttl: Int
)
