package com.benchmark;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.runtime.Micronaut;

import java.util.HashMap;
import java.util.Map;

@Controller
class RootController {
    @Get("/")
    public Map<String, Object> index() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "running");
        return response;
    }
}

public class Main {
    public static void main(String[] args) {
        Micronaut.run(Main.class, args);
    }
}
