package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

@Service
public class DatabaseService {
    private final JdbcTemplate jdbcTemplate;

    @Autowired
    public DatabaseService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public Optional<User> getUserById(Integer id) {
        try {
            Map<String, Object> userMap = jdbcTemplate.queryForMap(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?",
                id
            );

            User user = new User(
                (Integer) userMap.get("id"),
                (String) userMap.get("email"),
                (String) userMap.get("first_name"),
                (String) userMap.get("last_name"),
                userMap.get("age") != null ? (Integer) userMap.get("age") : null,
                ((java.sql.Timestamp) userMap.get("created_at")).toInstant()
            );

            return Optional.of(user);
        } catch (org.springframework.dao.EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<UserStats> getUserStats(Integer days) {
        List<Map<String, Object>> results = jdbcTemplate.queryForList(
            """
            SELECT
                u.id as user_id,
                CONCAT(u.first_name, ' ', u.last_name) as user_name,
                COUNT(DISTINCT o.id) as total_orders,
                COALESCE(SUM(oi.quantity * oi.price), 0) as total_value,
                COALESCE(AVG(oi.quantity * oi.price), 0) as average_value
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
                AND o.created_at >= NOW() - (INTERVAL '1 day' * ?)
                AND o.status = 'completed'
            LEFT JOIN order_items oi ON o.id = oi.order_id
            WHERE o.id IS NULL OR (o.created_at >= NOW() - (INTERVAL '1 day' * ?) AND o.status = 'completed')
            GROUP BY u.id, u.first_name, u.last_name
            HAVING COUNT(DISTINCT o.id) > 0
            ORDER BY total_value DESC
            LIMIT 100
            """,
            days, days
        );

        List<UserStats> stats = new ArrayList<>();
        for (Map<String, Object> row : results) {
            UserStats stat = new UserStats(
                ((Number) row.get("user_id")).intValue(),
                (String) row.get("user_name"),
                ((Number) row.get("total_orders")).intValue(),
                ((Number) row.get("total_value")).doubleValue(),
                ((Number) row.get("average_value")).doubleValue()
            );
            stats.add(stat);
        }

        return stats;
    }
}
