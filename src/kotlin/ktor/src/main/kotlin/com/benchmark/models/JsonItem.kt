package com.benchmark.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.Instant
import java.util.UUID

@Serializable
data class JsonItem(
    val id: Int,
    val name: String,
    val description: String,
    val timestamp: String,
    val random: String
) {
    companion object {
        fun create(id: Int): JsonItem {
            return JsonItem(
                id = id,
                name = "Item $id",
                description = "This is item number $id",
                timestamp = Instant.now().toString(),
                random = "data-${UUID.randomUUID()}"
            )
        }
    }
}
