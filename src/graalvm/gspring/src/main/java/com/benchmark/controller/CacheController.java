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
    private final CacheService cacheService;
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Autowired
    public CacheController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @GetMapping("/cache")
    public Map<String, Object> cache(@RequestParam(required = false) String key) {
        String cacheKey = key != null ? key : "test";

        String value = cacheService.getOrSet(cacheKey);
        boolean wasCached = value != null && !value.contains(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME).split("T")[0]);

        Map<String, Object> response = new HashMap<>();
        response.put("key", cacheKey);
        response.put("value", value);
        response.put("cached", wasCached);
        response.put("timestamp", LocalDateTime.now().format(formatter));
        return response;
    }
}
