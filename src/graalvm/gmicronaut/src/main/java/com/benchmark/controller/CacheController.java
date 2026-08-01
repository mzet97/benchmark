package com.benchmark.controller;

import com.benchmark.service.CacheService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.core.annotation.Nullable;

import jakarta.inject.Inject;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Controller
public class CacheController {

    // The TTL is part of the response contract and must match what is written
    // to Redis. See contracts/rest/canonical-payloads.md.
    private static final int CACHE_TTL_SECONDS = 300;
    private final CacheService cacheService;
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Inject
    public CacheController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @Get("/cache")
    public Map<String, Object> cache(@Nullable @QueryValue("key") String keyParam) {
        String key = keyParam != null ? keyParam : "test";

        // This used to call getOrSet three times per request -- three Redis
        // round trips -- and infer "cached" from the shape of the returned
        // string. The service reports it directly now.
        CacheService.CacheHit hit = cacheService.getOrSetWithSource(key);
        String value = hit.value();
        boolean wasCached = hit.cached();

        Map<String, Object> response = new HashMap<>();
        response.put("key", key);
        response.put("value", value);
        response.put("cached", wasCached);
        response.put("ttl", CACHE_TTL_SECONDS);
        response.put("timestamp", LocalDateTime.now().format(formatter));
        return response;
    }
}
