package com.benchmark.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ComplexOrderResult(
    @SerialName("user_id")
    val userId: Int,
    val email: String,
    @SerialName("order_count")
    val orderCount: Long,
    @SerialName("total_amount")
    val totalAmount: Double,
    @SerialName("avg_amount")
    val averageAmount: Double,
    @SerialName("days_since_first_order")
    val daysSinceFirstOrder: Long
)
