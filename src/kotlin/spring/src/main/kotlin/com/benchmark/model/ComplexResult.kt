package com.benchmark.model

data class ComplexResult(
    val userId: Int,
    val userName: String,
    val totalOrders: Long,
    val totalValue: Double,
    val averageOrderValue: Double
)

data class ComplexResponse(
    val periodDays: Int,
    val totalUsers: Int,
    val data: List<ComplexResult>
)
