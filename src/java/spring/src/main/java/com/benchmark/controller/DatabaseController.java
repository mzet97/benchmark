package com.benchmark.controller;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.benchmark.service.DatabaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
public class DatabaseController {
    private final DatabaseService databaseService;

    @Autowired
    public DatabaseController(DatabaseService databaseService) {
        this.databaseService = databaseService;
    }

    @GetMapping("/db/simple")
    public ResponseEntity<?> dbSimple(@RequestParam(required = false) Integer id) {
        if (id == null) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Bad Request",
                "message", "id parameter is required"
            ));
        }

        Optional<User> userOpt = databaseService.getUserById(id);
        if (userOpt.isEmpty()) {
            return ResponseEntity.status(404).body(Map.of(
                "error", "Not Found",
                "message", "User with id " + id + " not found"
            ));
        }

        User user = userOpt.get();
        return ResponseEntity.ok(Map.of(
            "id", user.getId(),
            "email", user.getEmail(),
            "firstName", user.getFirstName(),
            "lastName", user.getLastName(),
            "age", user.getAge(),
            "createdAt", user.getCreatedAt().toString()
        ));
    }

    @GetMapping("/db/complex")
    public ResponseEntity<?> dbComplex(@RequestParam(defaultValue = "30") int days) {
        if (days <= 0 || days > 365) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Bad Request",
                "message", "days must be between 1 and 365"
            ));
        }

        List<UserStats> stats = databaseService.getUserStats(days);

        List<Map<String, Object>> data = new ArrayList<>();
        for (UserStats stat : stats) {
            data.add(Map.of(
                "userId", stat.getUserId(),
                "userName", stat.getUserName(),
                "totalOrders", stat.getTotalOrders(),
                "totalValue", stat.getTotalValue(),
                "averageOrderValue", stat.getAverageOrderValue()
            ));
        }

        return ResponseEntity.ok(Map.of(
            "periodDays", days,
            "totalUsers", data.size(),
            "data", data
        ));
    }
}
