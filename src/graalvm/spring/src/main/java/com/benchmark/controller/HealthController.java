package com.benchmark.controller;

import com.benchmark.service.DatabaseService;
import com.benchmark.service.CacheService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
public class HealthController {
    private final DatabaseService databaseService;
    private final CacheService cacheService;

    @Autowired
    public HealthController(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        String dbStatus = "disconnected";
        String cacheStatus = "disconnected";

        try {
            databaseService.getUserById(1);
            dbStatus = "connected";
        } catch (Exception e) {
            dbStatus = "disconnected";
        }

        try {
            cacheService.getOrSet("test");
            cacheStatus = "connected";
        } catch (Exception e) {
            cacheStatus = "disconnected";
        }

        return Map.of(
            "status", dbStatus.equals("connected") && cacheStatus.equals("connected") ? "healthy" : "unhealthy",
            "version", "1.0.0",
            "timestamp", Instant.now().toString(),
            "database", dbStatus,
            "cache", cacheStatus
        );
    }

    @GetMapping("/healthz")
    public Map<String, Object> healthz() {
        return Map.of("status", "ok");
    }
}
