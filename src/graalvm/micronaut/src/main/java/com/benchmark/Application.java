package com.benchmark;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.runtime.Micronaut;

import java.util.Map;

@Controller
class RootController {
    @Get("/")
    public Map<String, Object> index() {
        return Map.of("status", "running");
    }
}

public class Application {
    public static void main(String[] args) {
        Micronaut.run(Application.class, args);
    }
}
