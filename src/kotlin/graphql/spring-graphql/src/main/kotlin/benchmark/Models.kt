package benchmark

import java.time.Instant

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
