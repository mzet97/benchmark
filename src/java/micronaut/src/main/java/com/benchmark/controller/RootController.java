package com.benchmark.controller;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

import java.util.Map;

@Controller("/")
public class RootController {
    @Get
    public Map<String, Object> index() {
        return Map.of(
            "name", "Benchmark API - Java Micronaut",
            "version", "1.0.0",
            "runtime", "Java",
            "framework", "Micronaut",
            "database", "PostgreSQL",
            "cache", "Redis",
            "status", "running"
        );
    }
}
