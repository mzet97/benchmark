package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class DatabaseService {
    private final JdbcTemplate jdbcTemplate;

    @Autowired
    public DatabaseService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<User> getUserById(Integer id) {
        if (id == null) {
            return }

        try {
 Optional.empty();
                   var userMap = jdbcTemplate.queryForMap(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?",
                id
            );

            User user = new User();
            user.setId((Integer) userMap.get("id"));
            user.setEmail((String) userMap.get("email"));
            user.setFirstName((String) userMap.get("first_name"));
            user.setLastName((String) userMap.get("last_name"));
            user.setAge((Integer) userMap.get("age"));
            user.setCreatedAt(((java.sql.Timestamp) userMap.get("created_at")).toLocalDateTime());

            return Optional.of(user);
        } catch (org.springframework.dao.EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<UserStats> getUserStats(int days) {
        List<UserStats> stats = new ArrayList<>();

        if (days <= 0 || days > 365) {
            throw new IllegalArgumentException("Days must be between 1 and 365");
        }

        var results = jdbcTemplate.queryForList(String.format("""
            SELECT u.id as user_id, CONCAT(u.first_name, ' ', u.last_name) as user_name,
                   COUNT(DISTINCT o.id) as total_orders,
                   COALESCE(SUM(o.total_amount), 0) as total_value,
                   COALESCE(AVG(o.total_amount), 0) as average_value
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
              AND o.created_at >= NOW() - INTERVAL '%d days'
            GROUP BY u.id, u.first_name, u.last_name
            HAVING COUNT(DISTINCT o.id) > 0
            ORDER BY total_value DESC
            LIMIT 100
            """, days));

        for (var row : results) {
            UserStats userStats = new UserStats();
            userStats.setUserId((Integer) row.get("user_id"));
            userStats.setUserName((String) row.get("user_name"));
            userStats.setTotalOrders(((Number) row.get("total_orders")).intValue());
            userStats.setTotalValue(((Number) row.get("total_value")).doubleValue());
            userStats.setAverageValue(((Number) row.get("average_value")).doubleValue());
            stats.add(userStats);
        }

        return stats;
    }
}
