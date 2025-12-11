package com.benchmark.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

import jakarta.inject.Inject;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class JsonController {
    private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    @Get("/json")
    public Map<String, Object> json() {
        List<Map<String, Object>> items = new ArrayList<>();
        String timestamp = LocalDateTime.now().format(formatter);

        for (int i = 0; i < 1000; i++) {
            Map<String, Object> item = new HashMap<>();
            item.put("id", i);
            item.put("name", "User " + i);
            item.put("email", "user" + i + "@example.com");
            item.put("timestamp", timestamp);
            items.add(item);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("items", items);
        response.put("count", items.size());
        response.put("timestamp", timestamp);
        return response;
    }
}
