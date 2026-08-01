package com.benchmark.controller;

import com.benchmark.Canonical;

import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;

import java.util.Map;

@Controller("/json")
public class JsonController {

    /**
     * The previous implementation emitted {id,name,email,timestamp} with
     * names like "User 3" and ignored ?n=, so it neither matched the payload
     * contract nor served the n=10/n=100 scenarios.
     */
    @Get
    public Map<String, Object> json(@QueryValue(value = "n", defaultValue = "") String n) {
        return Canonical.response(n);
    }
}
