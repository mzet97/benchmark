package com.benchmark.routes

import com.benchmark.services.CacheService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable
import java.time.Instant
import java.util.UUID

// The TTL is part of the response contract and must match what is written to
// Redis. See contracts/rest/canonical-payloads.md.
private const val CACHE_TTL_SECONDS = 300

@Serializable
private data class CacheResponse(
    val key: String,
    val value: String,
    val cached: Boolean,
    val ttl: Int,
    val timestamp: String,
)

fun Route.cacheRoutes(cacheService: CacheService) {
    get("/cache") {
        val key = call.request.queryParameters["key"] ?: "test"
        val newValue = "cached-value-${UUID.randomUUID()}"
        val value = cacheService.getOrSet(key, newValue, CACHE_TTL_SECONDS)
        // The contract carries a boolean plus the TTL, not a free-form
        // "source" string.
        call.respond(
            CacheResponse(
                key = key,
                value = value,
                cached = value != newValue,
                ttl = CACHE_TTL_SECONDS,
                timestamp = Instant.now().toString(),
            )
        )
    }
}
