package com.benchmark.controller;

import com.benchmark.service.CacheService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@RestController
public class CacheController {

    // The TTL is part of the response contract and must match what is written
    // to Redis. See contracts/rest/canonical-payloads.md.
    private static final int CACHE_TTL_SECONDS = 300;
    private final CacheService cacheService;
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Autowired
    public CacheController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @GetMapping("/cache")
    public Map<String, Object> cache(@RequestParam(required = false) String key) {
        String cacheKey = key != null ? key : "test";

        // "cached" used to be inferred from whether the stored string contained
        // today's date, which reports the opposite of what happened for
        // anything cached today. The service reports it directly now.
        CacheService.CacheHit hit = cacheService.getOrSetWithSource(cacheKey);
        String value = hit.value();
        boolean wasCached = hit.cached();

        Map<String, Object> response = new HashMap<>();
        response.put("key", cacheKey);
        response.put("value", value);
        response.put("cached", wasCached);
        response.put("ttl", CACHE_TTL_SECONDS);
        response.put("timestamp", LocalDateTime.now().format(formatter));
        return response;
    }
}
