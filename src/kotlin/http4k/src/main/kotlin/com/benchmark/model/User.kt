package com.benchmark.model

import java.time.LocalDateTime

data class User(
    val id: Int,
    val email: String,
    val firstName: String,
    val lastName: String,
    val age: Int?,
    val createdAt: LocalDateTime
) {
    val name: String get() = "$firstName $lastName"
    val isActive: Boolean get() = createdAt.isAfter(LocalDateTime.now().minusYears(1))
}
