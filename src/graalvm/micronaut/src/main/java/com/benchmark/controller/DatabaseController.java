package com.benchmark.controller;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.service.DatabaseService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.http.HttpResponse;

import jakarta.inject.Inject;
import java.time.Instant;
import java.util.*;

@Controller("/db")
public class DatabaseController {
    private final DatabaseService databaseService;

    @Inject
    public DatabaseController(DatabaseService databaseService) {
        this.databaseService = databaseService;
    }

    @Get("/simple")
    public HttpResponse<?> dbSimple(@QueryValue(defaultValue = "") String id) {
        if (id.isEmpty()) {
            return HttpResponse.badRequest(Map.of(
                "error", "Bad Request",
                "message", "id parameter is required"
            ));
        }

        int userId;
        try {
            userId = Integer.parseInt(id);
        } catch (NumberFormatException e) {
            return HttpResponse.badRequest(Map.of(
                "error", "Bad Request",
                "message", "id must be a number"
            ));
        }

        Optional<User> userOpt = databaseService.getUserById(userId);
        if (userOpt.isEmpty()) {
            return HttpResponse.notFound(Map.of(
                "error", "Not Found",
                "message", "User with id " + userId + " not found"
            ));
        }

        User user = userOpt.get();
        return HttpResponse.ok(Map.of(
            "id", user.getId(),
            "email", user.getEmail(),
            "first_name", user.getFirstName(),
            "last_name", user.getLastName(),
            "age", user.getAge(),
            "created_at", user.getCreatedAt().toString()
        ));
    }

    @Get("/complex")
    public HttpResponse<?> dbComplex(@QueryValue(defaultValue = "30") int days) {
        if (days <= 0 || days > 365) {
            return HttpResponse.badRequest(Map.of(
                "error", "Bad Request",
                "message", "days must be between 1 and 365"
            ));
        }

        List<UserStats> stats = databaseService.getUserStats(days);

        List<Map<String, Object>> data = new ArrayList<>();
        for (UserStats stat : stats) {
            data.add(Map.of(
                "user_id", stat.getUserId(),
                "user_name", stat.getUserName(),
                "total_orders", stat.getTotalOrders(),
                "total_value", stat.getTotalValue(),
                "average_value", stat.getAverageValue()
            ));
        }

        return HttpResponse.ok(Map.of(
            "period_days", days,
            "total_users", data.size(),
            "data", data,
            "timestamp", Instant.now().toString()
        ));
    }
}
