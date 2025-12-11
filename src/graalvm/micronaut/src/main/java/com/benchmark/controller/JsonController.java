package com.benchmark.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Map;

@Controller
public class JsonController {
    @Get("/json")
    public Map<String, Object> json() {
        var items = new ArrayList<Map<String, Object>>();
        String timestamp = Instant.now().toString();

        for (int i = 0; i < 1000; i++) {
            items.add(Map.of(
                "id", i,
                "name", "User " + i,
                "email", "user" + i + "@example.com",
                "timestamp", timestamp
            ));
        }

        return Map.of("items", items, "count", items.size(), "timestamp", timestamp);
    }
}
