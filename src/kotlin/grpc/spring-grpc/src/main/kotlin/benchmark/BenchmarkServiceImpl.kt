package benchmark

import benchmark.BenchmarkServiceGrpcKt
import io.grpc.Status
import io.grpc.StatusException
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.UUID

@Service
class BenchmarkServiceImpl(
    private val dbService: DatabaseService,
    private val cacheService: CacheService
) : BenchmarkServiceGrpcKt.BenchmarkServiceCoroutineImplBase() {

    private val version = System.getenv("APP_VERSION") ?: "1.0.0"

    // Scenario 1: Health check
    override suspend fun health(request: benchmark.HealthRequest): benchmark.HealthResponse {
        val dbStatus = dbService.healthCheck()
        val cacheStatus = cacheService.healthCheck()

        return benchmark.HealthResponse.newBuilder()
            .setStatus("ok")
            .setVersion(version)
            .setTimestamp(Instant.now().toString())
            .setDatabase(dbStatus)
            .setCache(cacheStatus)
            .build()
    }

    // Scenario 2: JSON serialization (1000 items)
    override suspend fun getJsonItems(request: benchmark.JsonItemsRequest): benchmark.JsonItemsResponse {
        val limit = if (request.limit > 0) request.limit else 1000
        val items = (1..limit).map { i ->
            benchmark.JsonItem.newBuilder()
                .setId(i)
                .setUuid(UUID.randomUUID().toString())
                .setName("Item $i")
                .setEmail("user${i}@benchmark.com")
                .setCreatedAt(Instant.now().toString())
                .setIsActive(i % 2 == 0)
                .build()
        }

        return benchmark.JsonItemsResponse.newBuilder()
            .addAllItems(items)
            .setCount(items.size)
            .setTimestamp(Instant.now().toString())
            .build()
    }

    // Scenario 3: Simple database query
    override suspend fun getUser(request: benchmark.GetUserRequest): benchmark.UserResponse {
        val user = dbService.getUser(request.id)
            ?: throw StatusException(Status.NOT_FOUND.withDescription("User with id ${request.id} not found"))

        return benchmark.UserResponse.newBuilder()
            .setId(user.id)
            .setEmail(user.email)
            .setFirstName(user.firstName)
            .setLastName(user.lastName)
            .setAge(user.age)
            .setCreatedAt(user.createdAt)
            .build()
    }

    // Scenario 4: Complex database query (JOIN + aggregation)
    override suspend fun getComplexOrders(request: benchmark.ComplexOrdersRequest): benchmark.ComplexOrdersResponse {
        val days = if (request.days > 0) request.days else 30
        val data = dbService.getComplexOrders(days)

        val orderStats = data.map { stat ->
            benchmark.UserOrderStats.newBuilder()
                .setUserId(stat.userId)
                .setUserName(stat.userName)
                .setTotalOrders(stat.totalOrders)
                .setTotalValue(stat.totalValue)
                .setAverageOrderValue(stat.averageOrderValue)
                .build()
        }

        return benchmark.ComplexOrdersResponse.newBuilder()
            .setPeriodDays(days)
            .setTotalUsers(orderStats.size)
            .addAllData(orderStats)
            .build()
    }

    // Scenario 5: Cache hit/miss
    override suspend fun getCacheValue(request: benchmark.CacheRequest): benchmark.CacheResponse {
        val key = request.key
        val result = cacheService.get(key)

        return if (result.hit) {
            benchmark.CacheResponse.newBuilder()
                .setKey(key)
                .setValue(result.value!!)
                .setCached(true)
                .setTtl(300)
                .setTimestamp(Instant.now().toString())
                .build()
        } else {
            val value = "value-${System.currentTimeMillis()}"
            cacheService.set(key, value, 300)

            benchmark.CacheResponse.newBuilder()
                .setKey(key)
                .setValue(value)
                .setCached(false)
                .setTtl(300)
                .setTimestamp(Instant.now().toString())
                .build()
        }
    }
}
