package com.benchmark.models

import kotlinx.serialization.Serializable

// Mirrors UserOrderStats in contracts/grpc/benchmark.proto. The previous
// ComplexOrderResult carried {userId, email, order_count, total_amount,
// avg_amount, days_since_first_order} -- a shape no other implementation
// emitted. See contracts/rest/canonical-payloads.md.
@Serializable
data class UserOrderStats(
    val userId: Int,
    val userName: String,
    val totalOrders: Long,
    val totalValue: Double,
    val averageOrderValue: Double,
)
