package com.benchmark.controller

import com.benchmark.service.CacheService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.Instant

// The TTL is part of the response contract and must match what is written to
// Redis. See contracts/rest/canonical-payloads.md.
private const val CACHE_TTL_SECONDS = 300

@RestController
class CacheController(
    private val cacheService: CacheService
) {
    @GetMapping("/cache")
    fun cache(@RequestParam(defaultValue = "test") key: String): Map<String, Any> {
        // No Thread.sleep(50) here, and no println per request. Both were
        // invariante 1 violations (docs/ACTION_PLAN.md): hidden work on the
        // measured path.
        //
        // The sleep was not a rounding error on this implementation -- it was
        // the whole result. /cache measured 1,962 rps with a 51.99 ms p99
        // against a theoretical ceiling of 100 connections / 50 ms = 2,000 rps:
        // the cache read never hit, so every single request paid the sleep, and
        // the number described a hardcoded delay rather than Redis or Spring.
        // For comparison, http4k on the same JVM and the same Redis did 186,825
        // rps on this endpoint.
        //
        // The println was the second half: a synchronized stdout write per
        // request, in a blocking servlet model, which is exactly the 2-3x that
        // deploy/k3s/base/configmap.yaml sets LOG_LEVEL=error to avoid.
        val (value, cached) = cacheService.getOrSet(key, {
            "Cached value for $key at ${Instant.now()}"
        }, CACHE_TTL_SECONDS)

        return mapOf(
            "key" to key,
            "value" to value,
            "cached" to cached,
            "ttl" to CACHE_TTL_SECONDS,
            "timestamp" to Instant.now().toString()
        )
    }
}
