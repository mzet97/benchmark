package com.benchmark.controller;

import com.benchmark.service.DatabaseService;
import com.benchmark.service.CacheService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

import jakarta.inject.Inject;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Controller
public class HealthController {
    private final DatabaseService databaseService;
    private final CacheService cacheService;

    @Inject
    public HealthController(DatabaseService databaseService, CacheService cacheService) {
        this.databaseService = databaseService;
        this.cacheService = cacheService;
    }

    @Get("/health")
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
            if (cacheService.ping()) {
                cacheStatus = "connected";
            }
        } catch (Exception e) {
            cacheStatus = "disconnected";
        }

        Map<String, Object> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("version", "1.0.0");
        response.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        response.put("database", dbStatus);
        response.put("cache", cacheStatus);
        return response;
    }

    @Get("/healthz")
    public Map<String, Object> healthz() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "ok");
        return response;
    }
}
