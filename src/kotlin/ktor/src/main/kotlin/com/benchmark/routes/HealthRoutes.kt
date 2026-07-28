package com.benchmark.routes

import com.benchmark.services.CacheService
import com.benchmark.services.DatabaseService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant

fun Route.healthRoutes(dbService: DatabaseService, cacheService: CacheService) {
    get("/health") {
        val dbOk = dbService.healthCheck()
        val cacheOk = cacheService.healthCheck()
        val status = if (dbOk && cacheOk) "healthy" else "unhealthy"
        val code = if (dbOk && cacheOk) HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
        call.respondText(
            """{"status":"$status","database":"${if (dbOk) "connected" else "disconnected"}","cache":"${if (cacheOk) "connected" else "disconnected"}","timestamp":"${Instant.now()}"}""",
            ContentType.Application.Json, code
        )
    }

    get("/healthz") {
        call.respondText("""{"status":"ok"}""", ContentType.Application.Json)
    }
}
