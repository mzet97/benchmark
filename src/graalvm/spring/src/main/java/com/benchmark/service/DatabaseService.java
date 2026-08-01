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
            """,
            days, days
        );

        List<UserStats> stats = new ArrayList<>();
        for (Map<String, Object> row : results) {
            UserStats stat = new UserStats(
                ((Number) row.get("userId")).intValue(),
                (String) row.get("userName"),
                ((Number) row.get("totalOrders")).intValue(),
                ((Number) row.get("totalValue")).doubleValue(),
                ((Number) row.get("averageOrderValue")).doubleValue()
            );
            stats.add(stat);
        }

        return stats;
    }
}
