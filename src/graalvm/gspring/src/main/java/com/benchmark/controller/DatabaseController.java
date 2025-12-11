package com.benchmark.controller;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.service.DatabaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
public class DatabaseController {
    private final DatabaseService databaseService;

    @Autowired
    public DatabaseController(DatabaseService databaseService) {
        this.databaseService = databaseService;
    }

    @GetMapping("/db/simple")
    public Object dbSimple(@RequestParam(required = false) String id) {
        Integer userId = 1;
        if (id != null && !id.isEmpty()) {
            try {
                userId = Integer.parseInt(id);
            } catch (NumberFormatException e) {
                Map<String, Object> error = new HashMap<>();
                error.put("error", "Bad Request");
                error.put("message", "id must be a number");
                return error;
            }
        }

        Optional<User> user = databaseService.getUserById(userId);
        if (user.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("error", "Not Found");
            error.put("message", "User with id " + userId + " not found");
            return error;
        }

        return user.get();
    }

    @GetMapping("/db/complex")
    public Map<String, Object> dbComplex(@RequestParam(required = false) String days) {
        Integer daysInt = 30;
        if (days != null && !days.isEmpty()) {
            try {
                daysInt = Integer.parseInt(days);
                if (daysInt <= 0 || daysInt > 365) {
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

        List<UserStats> stats = databaseService.getUserStats(daysInt);

        Map<String, Object> response = new HashMap<>();
        response.put("period_days", daysInt);
        response.put("total_users", stats.size());
        response.put("data", stats);
        return response;
    }
}
