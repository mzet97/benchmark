package com.benchmark.routes

import com.benchmark.services.CacheService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant
import java.util.UUID

fun Route.cacheRoutes(cacheService: CacheService) {
    get("/cache") {
        val key = call.request.queryParameters["key"] ?: "test"
        val newValue = "cached-value-${UUID.randomUUID()}"
        val value = cacheService.getOrSet(key, newValue, 300)
        val source = if (value == newValue) "generated" else "cache"
        call.respondText(
            """{"key":"$key","value":"$value","source":"$source","timestamp":"${Instant.now()}"}""",
            ContentType.Application.Json
        )
    }
}
