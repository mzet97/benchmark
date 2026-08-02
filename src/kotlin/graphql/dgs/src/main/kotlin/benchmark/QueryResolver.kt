package benchmark

import com.netflix.graphql.dgs.DgsComponent
import com.netflix.graphql.dgs.DgsQuery
import com.netflix.graphql.dgs.InputArgument
import java.time.Instant
import java.util.*

@DgsComponent
class QueryResolver(
    private val databaseService: DatabaseService,
    private val cacheService: CacheService
) {

    @DgsQuery
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

    @DgsQuery
    fun jsonItems(@InputArgument limit: Int?): JsonItemsResult {
        val count = Canonical.itemCount(limit)
        val now = Instant.now().toString()
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

    @DgsQuery
    fun user(@InputArgument id: Int): User? {
        return databaseService.getUser(id)
    }

    @DgsQuery
    fun complexOrders(@InputArgument days: Int?): ComplexOrdersResult {
        val actualDays = days ?: 30
        val data = databaseService.getComplexOrders(actualDays)
        return ComplexOrdersResult(
            periodDays = actualDays,
            totalUsers = data.size,
            data = data
        )
    }

    @DgsQuery
    fun cache(@InputArgument key: String): CacheEntry {
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
