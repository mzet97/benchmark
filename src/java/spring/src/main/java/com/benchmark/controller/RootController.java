package com.benchmark.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class RootController {
    @GetMapping("/")
    public Map<String, Object> index() {
        return Map.of(
            "name", "Benchmark API - Java Spring Boot",
            "version", "1.0.0",
            "runtime", "Java",
            "framework", "Spring Boot",
            "database", "PostgreSQL",
            "cache", "Redis",
            "status", "running"
        );
    }
}
