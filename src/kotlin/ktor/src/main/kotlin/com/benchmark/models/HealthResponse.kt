package com.benchmark.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class HealthResponse(
    val status: String,
    val database: String,
    val cache: String,
    val timestamp: String
)
