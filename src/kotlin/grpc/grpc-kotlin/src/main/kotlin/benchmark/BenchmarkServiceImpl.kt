package benchmark

import dev.benchmark.grpc.Benchmark
import dev.benchmark.grpc.BenchmarkServiceGrpcKt
import io.grpc.Status
import io.grpc.StatusException
import java.time.Instant

class BenchmarkServiceImpl(
    private val dbService: DatabaseService,
    private val cacheService: CacheService
) : BenchmarkServiceGrpcKt.BenchmarkServiceCoroutineImplBase() {

    private val version = System.getenv("APP_VERSION") ?: "1.0.0"

    // Scenario 1: Health check
    override suspend fun health(request: Benchmark.HealthRequest): Benchmark.HealthResponse {
        val dbStatus = dbService.healthCheck()
        val cacheStatus = cacheService.healthCheck()

        return Benchmark.HealthResponse.newBuilder()
            .setStatus("ok")
            .setVersion(version)
            .setTimestamp(Instant.now().toString())
            .setDatabase(dbStatus)
            .setCache(cacheStatus)
            .build()
    }

    // Scenario 2: JSON serialization (1000 items)
    override suspend fun getJsonItems(request: Benchmark.JsonItemsRequest): Benchmark.JsonItemsResponse {
        val count = Canonical.itemCount(request.limit)
        val items = (0 until count).map { i ->
            Benchmark.JsonItem.newBuilder()
                .setId(i)
                .setUuid(Canonical.uuid(i))
                .setName(Canonical.name(i))
                .setEmail(Canonical.email(i))
                .setCreatedAt(Canonical.CREATED_AT)
                .setIsActive(Canonical.isActive(i))
                .build()
        }

        return Benchmark.JsonItemsResponse.newBuilder()
            .addAllItems(items)
            .setCount(items.size)
            .setTimestamp(Instant.now().toString())
            .build()
    }

    // Scenario 3: Simple database query
    override suspend fun getUser(request: Benchmark.GetUserRequest): Benchmark.UserResponse {
        val user = dbService.getUser(request.id)
            ?: throw StatusException(Status.NOT_FOUND.withDescription("User with id ${request.id} not found"))

        return Benchmark.UserResponse.newBuilder()
            .setId(user.id)
            .setEmail(user.email)
            .setFirstName(user.firstName)
            .setLastName(user.lastName)
            .setAge(user.age)
            .setCreatedAt(user.createdAt)
            .build()
    }

    // Scenario 4: Complex database query (JOIN + aggregation)
    override suspend fun getComplexOrders(request: Benchmark.ComplexOrdersRequest): Benchmark.ComplexOrdersResponse {
        val days = if (request.days > 0) request.days else 30
        val data = dbService.getComplexOrders(days)

        val orderStats = data.map { stat ->
            Benchmark.UserOrderStats.newBuilder()
                .setUserId(stat.userId)
                .setUserName(stat.userName)
                .setTotalOrders(stat.totalOrders)
                .setTotalValue(stat.totalValue)
                .setAverageOrderValue(stat.averageOrderValue)
                .build()
        }

        return Benchmark.ComplexOrdersResponse.newBuilder()
            .setPeriodDays(days)
            .setTotalUsers(orderStats.size)
            .addAllData(orderStats)
            .build()
    }

    // Scenario 5: Cache hit/miss
    override suspend fun getCacheValue(request: Benchmark.CacheRequest): Benchmark.CacheResponse {
        val key = request.key
        val result = cacheService.get(key)

        return if (result.hit) {
            Benchmark.CacheResponse.newBuilder()
                .setKey(key)
                .setValue(result.value!!)
                .setCached(true)
                .setTtl(300)
                .setTimestamp(Instant.now().toString())
                .build()
        } else {
            val value = "value-${System.currentTimeMillis()}"
            cacheService.set(key, value, 300)

            Benchmark.CacheResponse.newBuilder()
                .setKey(key)
                .setValue(value)
                .setCached(false)
                .setTtl(300)
                .setTimestamp(Instant.now().toString())
                .build()
        }
    }
}
