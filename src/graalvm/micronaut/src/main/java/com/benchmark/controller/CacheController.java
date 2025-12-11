package com.benchmark.controller;

import com.benchmark.service.CacheService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;

import jakarta.inject.Inject;
import java.time.Instant;
import java.util.Map;

@Controller
public class CacheController {
    private final CacheService cacheService;

    @Inject
    public CacheController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @Get("/cache")
    public Map<String, Object> cache(@QueryValue(defaultValue = "test") String key) {
        CacheService.CacheResult result = cacheService.getOrSet(key);

        return Map.of(
            "key", result.getKey(),
            "value", result.getValue(),
            "cached", result.isCached(),
            "timestamp", Instant.now().toString()
        );
    }
}
