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
            return Optional.empty();
        }

        try {
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

        var results = jdbcTemplate.queryForList("""
            -- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
            -- query joined order_items, aggregated quantity*price and ordered without
            -- a tiebreak, so it ran a heavier query than the other implementations and
            -- its rows came back in arbitrary order among equal values.
            SELECT
                u.id AS "userId",
                u.first_name || ' ' || u.last_name AS "userName",
                COUNT(o.id) AS "totalOrders",
                COALESCE(SUM(o.total_amount), 0) AS "totalValue",
                COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
                WHERE o.created_at >= NOW() - INTERVAL '1 day' * ?
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY "totalOrders" DESC, u.id
            LIMIT 100
            """, days);

        for (var row : results) {
            UserStats userStats = new UserStats();
            userStats.setUserId((Integer) row.get("userId"));
            userStats.setUserName((String) row.get("userName"));
            userStats.setTotalOrders(((Number) row.get("totalOrders")).intValue());
            userStats.setTotalValue(((Number) row.get("totalValue")).doubleValue());
            userStats.setAverageOrderValue(((Number) row.get("averageOrderValue")).doubleValue());
            stats.add(userStats);
        }

        return stats;
    }
}
