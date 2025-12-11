package com.benchmark.controller

import com.benchmark.service.CacheService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.Instant

@RestController
class CacheController(
    private val cacheService: CacheService
) {
    @GetMapping("/cache")
    fun cache(@RequestParam(defaultValue = "test") key: String): Map<String, Any> {
        val (value, cached) = cacheService.getOrSet(key, {
            Thread.sleep(50) // Simulate work
            "Cached value for $key at ${Instant.now()}"
        }, 300)

        println("Cache operation for key: $key, cached: $cached")

        return mapOf(
            "key" to key,
            "value" to value,
            "cached" to cached,
            "timestamp" to Instant.now().toString()
        )
    }
}
