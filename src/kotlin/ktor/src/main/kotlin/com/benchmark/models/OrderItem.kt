package com.benchmark.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class OrderItem(
    val id: Int,
    @SerialName("order_id")
    val orderId: Int,
    @SerialName("product_name")
    val productName: String,
    val quantity: Int,
    val price: Double,
    @SerialName("created_at")
    val createdAt: String
)
