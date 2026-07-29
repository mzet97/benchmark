package benchmark

import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.stereotype.Controller
import java.util.UUID

@Controller
class QueryController(
    private val databaseService: DatabaseService,
    private val cacheService: CacheService
) {

    @QueryMapping
    fun health(): Health {
        val dbOk = databaseService.checkHealth()
        val cacheOk = cacheService.checkHealth()
        return Health(
            status = if (dbOk && cacheOk) "healthy" else "unhealthy",
            version = "1.0.0",
            timestamp = java.time.Instant.now().toString(),
            database = if (dbOk) "connected" else "disconnected",
            cache = if (cacheOk) "connected" else "disconnected"
        )
    }

    @QueryMapping
    fun jsonItems(@Argument limit: Int): JsonItemsResult {
        val timestamp = java.time.Instant.now().toString()
        val items = (1..limit).map { i ->
            JsonItem(
                id = i,
                uuid = UUID.randomUUID().toString(),
                name = "Item $i",
                email = "user${i}@example.com",
                createdAt = timestamp,
                isActive = i % 2 == 0
            )
        }
        return JsonItemsResult(
            items = items,
            count = limit,
            timestamp = timestamp
        )
    }

    @QueryMapping
    fun user(@Argument id: Int): User? {
        return databaseService.getUser(id)
    }

    @QueryMapping
    fun complexOrders(@Argument days: Int): ComplexOrdersResult {
        val data = databaseService.getComplexOrders(days)
        return ComplexOrdersResult(
            periodDays = days,
            totalUsers = data.size,
            data = data
        )
    }

    @QueryMapping
    fun cache(@Argument key: String): CacheEntry {
        val cached = cacheService.get(key)
        if (cached != null) {
            return CacheEntry(
                key = key,
                value = cached,
                cached = true,
                ttl = 300
            )
        }
        val value = "Cache value for $key at ${java.time.Instant.now()}"
        cacheService.set(key, value, 300)
        return CacheEntry(
            key = key,
            value = value,
            cached = false,
            ttl = 300
        )
    }
}
