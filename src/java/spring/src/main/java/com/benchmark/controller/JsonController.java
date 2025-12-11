package com.benchmark.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Map;

@RestController
public class JsonController {
    @GetMapping("/json")
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
