package com.benchmark.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Order(
    val id: Int,
    @SerialName("userId")
    val userId: Int,
    @SerialName("total_amount")
    val totalAmount: Double,
    val status: String,
    @SerialName("createdAt")
    val createdAt: String
)
