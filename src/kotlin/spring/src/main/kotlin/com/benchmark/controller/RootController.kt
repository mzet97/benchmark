package com.benchmark.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController

@RestController
class RootController {
    @GetMapping("/")
    fun root(): Map<String, Any> {
        return mapOf(
            "name" to "Benchmark API - Kotlin Spring Boot",
            "version" to "1.0.0",
            "description" to "High-performance REST API benchmark",
            "runtime" to "Kotlin",
            "framework" to "Spring Boot",
            "endpoints" to mapOf(
                "health" to "/health",
                "healthz" to "/healthz",
                "json" to "/json",
                "db_simple" to "/db/simple?id=1",
                "db_complex" to "/db/complex?days=30",
                "cache" to "/cache?key=test"
            ),
            "status" to "running"
        )
    }
}
