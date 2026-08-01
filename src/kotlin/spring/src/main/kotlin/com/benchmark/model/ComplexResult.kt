package com.benchmark.model

data class ComplexResult(
    val userId: Int,
    val userEmail: String,
    val totalOrders: Long,
    val totalValue: Double,
    val averageOrderValue: Double,
    val daysSinceFirstOrder: Double
)

data class ComplexResponse(
    val periodDays: Int,
    val totalUsers: Int,
    val data: List<ComplexResult>
)
