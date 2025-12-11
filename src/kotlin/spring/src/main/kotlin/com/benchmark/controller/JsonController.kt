package com.benchmark.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import java.time.Instant

@RestController
class JsonController {
    @GetMapping("/json")
    fun json(): Map<String, Any> {
        val items = (0..999).map {
            mapOf(
                "id" to it,
                "name" to "User $it",
                "email" to "user$it@example.com",
                "active" to true,
                "tags" to listOf("benchmark", "test", "api")
            )
        }
        return mapOf(
            "items" to items,
            "count" to items.size,
            "timestamp" to Instant.now().toString()
        )
    }
}
