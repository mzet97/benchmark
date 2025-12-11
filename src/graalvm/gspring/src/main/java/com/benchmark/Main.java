package com.benchmark;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
public class Main {
    public static void main(String[] args) {
        SpringApplication.run(Main.class, args);
    }

    @RestController
    static class RootController {
        @GetMapping("/")
        public Map<String, Object> index() {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "running");
            return response;
        }
    }
}
