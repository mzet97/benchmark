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
    private final CacheService cacheService;
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Inject
    public CacheController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @Get("/cache")
    public Map<String, Object> cache(@Nullable @QueryValue("key") String keyParam) {
        String key = keyParam != null ? keyParam : "test";

        String value = cacheService.getOrSet(key);
        boolean wasCached = cacheService.getOrSet(key).startsWith("cached-value-") &&
                           !cacheService.getOrSet(key).contains(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME).split("T")[0]);

        Map<String, Object> response = new HashMap<>();
        response.put("key", key);
        response.put("value", value);
        response.put("cached", wasCached);
        response.put("timestamp", LocalDateTime.now().format(formatter));
        return response;
    }
}
