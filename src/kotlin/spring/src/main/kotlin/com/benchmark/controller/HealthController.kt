package com.benchmark.controller

import com.benchmark.service.DatabaseService
import com.benchmark.service.CacheService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import java.time.Instant

@RestController
class HealthController(
    private val databaseService: DatabaseService,
    private val cacheService: CacheService
) {
    @GetMapping("/health")
    fun health(): Map<String, Any> {
        val dbHealthy = databaseService.healthCheck()
        val cacheHealthy = cacheService.ping()

        return mapOf(
            "status" to if (dbHealthy && cacheHealthy) "healthy" else "unhealthy",
            "timestamp" to Instant.now().toString(),
            "database" to if (dbHealthy) "healthy" else "unhealthy",
            "cache" to if (cacheHealthy) "healthy" else "unhealthy"
        )
    }

    @GetMapping("/healthz")
    fun healthz(): String {
        val dbHealthy = databaseService.healthCheck()
        val cacheHealthy = cacheService.ping()

        return if (dbHealthy && cacheHealthy) {
            "OK"
        } else {
            "Service Unavailable"
        }
    }
}
