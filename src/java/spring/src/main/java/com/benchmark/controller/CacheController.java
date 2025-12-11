package com.benchmark.controller;

import com.benchmark.service.CacheService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
public class CacheController {
    private final CacheService cacheService;

    @Autowired
    public CacheController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @GetMapping("/cache")
    public Map<String, Object> cache(@RequestParam(defaultValue = "test") String key) {
        var result = cacheService.getOrSet(key);

        return Map.of(
            "key", result.getKey(),
            "value", result.getValue(),
            "cached", result.isCached(),
            "timestamp", Instant.now().toString()
        );
    }
}
