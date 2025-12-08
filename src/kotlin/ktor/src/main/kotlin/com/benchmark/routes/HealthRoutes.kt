package com.benchmark.routes

import com.benchmark.models.HealthResponse
import com.benchmark.services.CacheService
import com.benchmark.services.DatabaseService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant

fun Route.healthRoutes(dbService: DatabaseService, cacheService: CacheService) {
    route("/health") {
        get {
            val dbHealthy = dbService.healthCheck()
            val cacheHealthy = cacheService.healthCheck()

            val response = HealthResponse(
                status = if (dbHealthy && cacheHealthy) "healthy" else "unhealthy",
                database = if (dbHealthy) "connected" else "disconnected",
                cache = if (cacheHealthy) "connected" else "disconnected",
                timestamp = Instant.now().toString()
            )

            if (dbHealthy && cacheHealthy) {
                call.respond(HttpStatusCode.OK, response)
            } else {
                call.respond(HttpStatusCode.ServiceUnavailable, response)
            }
        }
    }
}
