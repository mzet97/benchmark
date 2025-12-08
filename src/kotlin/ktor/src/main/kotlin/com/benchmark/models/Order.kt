package com.benchmark.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Order(
    val id: Int,
    @SerialName("user_id")
    val userId: Int,
    @SerialName("total_amount")
    val totalAmount: Double,
    val status: String,
    @SerialName("created_at")
    val createdAt: String
)
