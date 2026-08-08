package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

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
                ((Number) userMap.get("id")).intValue(),
                (String) userMap.get("email"),
                (String) userMap.get("first_name"),
                (String) userMap.get("last_name"),
                userMap.get("age") != null ? ((Number) userMap.get("age")).intValue() : null,
                userMap.get("created_at") instanceof Timestamp
                    ? ((Timestamp) userMap.get("created_at")).toLocalDateTime()
                    : (LocalDateTime) userMap.get("created_at")
            );

            return Optional.of(user);
        } catch (org.springframework.dao.EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<UserStats> getUserStats(Integer days) {
        // Normative SQL, see contracts/rest/canonical-payloads.md. Previously
        // this was a Spring Data JPA native @Query that projected straight into
        // the UserStats DTO. Native-query DTO projection relies on a
        // constructor whose argument types match the column types, but
        // COUNT()/SUM()/AVG() come back as Long/BigDecimal -- not the
        // Integer/Double the constructor declares -- so the mapper threw and
        // /db/complex returned HTTP 500. JdbcTemplate with explicit Number
        // narrowing (as the sibling graalvm/spring impl does) avoids that.
        List<Map<String, Object>> results = jdbcTemplate.queryForList(
            """
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
            days
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
