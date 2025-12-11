package com.benchmark.route

import com.benchmark.service.DatabaseService
import com.benchmark.service.CacheService
import org.http4k.core.HttpHandler
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.OK
import org.http4k.core.Status.Companion.SERVICE_UNAVAILABLE
import org.http4k.routing.HttpRoutingReceiver

fun healthRoutes(databaseService: DatabaseService, cacheService: CacheService): HttpRoutingReceiver {
    return routes(
        "/health" bind { _: Request ->
            val dbHealthy = databaseService.healthCheck()
            val cacheHealthy = cacheService.ping()

            val status = if (dbHealthy && cacheHealthy) "healthy" else "unhealthy"

            Response(OK).body(
                """{"status":"$status","timestamp":"${java.time.Instant.now()}","database":${if (dbHealthy) "\"healthy\"" else "\"unhealthy\""},"cache":${if (cacheHealthy) "\"healthy\"" else "\"unhealthy\""}}"""
            )
        },
        "/healthz" bind { _: Request ->
            val dbHealthy = databaseService.healthCheck()
            val cacheHealthy = cacheService.ping()

            if (dbHealthy && cacheHealthy) {
                Response(OK).body("OK")
            } else {
                Response(SERVICE_UNAVAILABLE).body("Service Unavailable")
            }
        }
    )
}
