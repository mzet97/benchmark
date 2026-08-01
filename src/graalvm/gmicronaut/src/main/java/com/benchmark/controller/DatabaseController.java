package com.benchmark.controller;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.service.DatabaseService;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;
import io.micronaut.http.annotation.QueryValue;
import io.micronaut.core.annotation.Nullable;

import jakarta.inject.Inject;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Controller("/db")
public class DatabaseController {
    private final DatabaseService databaseService;

    @Inject
    public DatabaseController(DatabaseService databaseService) {
        this.databaseService = databaseService;
    }

    @Get("/simple")
    public Object dbSimple(@Nullable @QueryValue("id") String idParam) {
        Integer id = 1;
        if (idParam != null && !idParam.isEmpty()) {
            try {
                id = Integer.parseInt(idParam);
            } catch (NumberFormatException e) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "Bad Request");
                error.put("message", "id must be a number");
                return error;
            }
        }

        Optional<User> user = databaseService.getUserById(id);
        if (user.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Not Found");
            error.put("message", "User with id " + id + " not found");
            return error;
        }

        return user.get();
    }

    @Get("/complex")
    public Map<String, Object> dbComplex(@Nullable @QueryValue("days") String daysParam) {
        Integer days = 30;
        if (daysParam != null && !daysParam.isEmpty()) {
            try {
                days = Integer.parseInt(daysParam);
                if (days <= 0 || days > 365) {
                    Map<String, Object> error = new HashMap<>();
                    error.put("error", "Bad Request");
                    error.put("message", "days must be between 1 and 365");
                    return error;
                }
            } catch (NumberFormatException e) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "Bad Request");
                error.put("message", "days must be a number");
                return error;
            }
        }

        List<UserStats> stats = databaseService.getUserStats(days);

        Map<String, Object> response = new HashMap<>();
        response.put("periodDays", days);
        response.put("totalUsers", stats.size());
        response.put("data", stats);
        return response;
    }
}
