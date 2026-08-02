package com.benchmark.controller;

import com.benchmark.Canonical;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class JsonController {

    /**
     * The previous implementation emitted {id,name,email,timestamp} with
     * names like "User 3" and ignored ?n=, so it neither matched the payload
     * contract nor served the n=10/n=100 scenarios.
     */
    @GetMapping("/json")
    public Map<String, Object> json(@RequestParam(name = "n", required = false) String n) {
        return Canonical.response(n);
    }
}
