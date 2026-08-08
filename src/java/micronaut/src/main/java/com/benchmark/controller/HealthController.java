package com.benchmark.controller;

import com.benchmark.service.DatabaseService;
import com.benchmark.service.CacheService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import jakarta.inject.Inject;

import java.time.Instant;
import java.util.LinkedHashMap;
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
        // Contract: {"status","version","timestamp","database","cache"} with HTTP 200.
        // The parity gate uses `curl -sf`, which treats any non-200 as a hard
        // failure. Catch Throwable (not Exception) so a failing Hikari pool or
        // Redis client cannot surface as 500 and make the endpoint look dead;
        // per-dependency state is reported in the values.
        String dbStatus = "down";
        String cacheStatus = "down";

        try {
            databaseService.getUserById(1);
            dbStatus = "up";
        } catch (Throwable t) {
            dbStatus = "down";
        }

        try {
            cacheService.getOrSet("__healthcheck__");
            cacheStatus = "up";
        } catch (Throwable t) {
            cacheStatus = "down";
        }

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "up".equals(dbStatus) && "up".equals(cacheStatus) ? "ok" : "degraded");
        response.put("version", "1.0.0");
        response.put("timestamp", Instant.now().toString());
        response.put("database", dbStatus);
        response.put("cache", cacheStatus);
        return response;
    }

    @Get("/healthz")
    public Map<String, Object> healthz() {
        return Map.of("status", "ok");
    }
}
