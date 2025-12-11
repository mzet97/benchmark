package com.benchmark.route

import com.benchmark.service.CacheService
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.OK
import org.http4k.routing.HttpRoutingReceiver

fun cacheRoutes(cacheService: CacheService): HttpRoutingReceiver {
    return routes(
        "/cache" bind { req: Request ->
            val key = req.query("key") ?: "test"

            val (value, cached) = cacheService.getOrSet(key, {
                Thread.sleep(50) // Simulate work
                "Cached value for $key at ${java.time.Instant.now()}"
            }, 300)

            println("Cache operation for key: $key, cached: $cached")

            Response(OK).body(
                """{"key":"$key","value":"$value","cached":$cached,"timestamp":"${java.time.Instant.now()}"}"""
            )
        }
    )
}
