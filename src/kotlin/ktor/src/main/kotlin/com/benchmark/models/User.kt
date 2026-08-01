package com.benchmark.models

import kotlinx.serialization.Serializable

// Mirrors UserResponse in contracts/grpc/benchmark.proto. The @SerialName
// annotations used to pin snake_case wire names.
// See contracts/rest/canonical-payloads.md.
@Serializable
data class User(
    val id: Int,
    val email: String,
    val firstName: String,
    val lastName: String,
    val age: Int? = null,
    val createdAt: String
)
