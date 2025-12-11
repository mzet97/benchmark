package com.benchmark.controller;

import com.benchmark.service.DatabaseService;
import com.benchmark.service.CacheService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.Map;

@Controller("/health")
public class HealthController {
    private final DatabaseService databaseService;
    private final CacheService cacheService;

    @Inject
    public HealthController(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    @Get
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

    @Get("/healthz")
    public Map<String, Object> healthz() {
        return Map.of("status", "ok");
    }
}
