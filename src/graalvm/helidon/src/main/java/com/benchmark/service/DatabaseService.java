package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class DatabaseService {
    private final HikariDataSource dataSource;

    public DatabaseService(HikariDataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Optional<User> getUserById(Integer id) {
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                 "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?")) {
            stmt.setInt(1, id);
            ResultSet rs = stmt.executeQuery();

            if (!rs.next()) {
                return Optional.empty();
            }

            User user = new User(
                rs.getInt("id"),
                rs.getString("email"),
                rs.getString("first_name"),
                rs.getString("last_name"),
                rs.getObject("age", Integer.class),
                rs.getTimestamp("created_at").toInstant()
            );

            return Optional.of(user);
        } catch (SQLException e) {
            throw new RuntimeException("Error fetching user", e);
        }
    }

    public List<UserStats> getUserStats(Integer days) {
        List<UserStats> stats = new ArrayList<>();

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(
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
                 """)) {
            stmt.setInt(1, days);
            stmt.setInt(2, days);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                UserStats stat = new UserStats(
                    rs.getInt("userId"),
                    rs.getString("userName"),
                    rs.getInt("totalOrders"),
                    rs.getDouble("totalValue"),
                    rs.getDouble("averageOrderValue")
                );
                stats.add(stat);
            }

            return stats;
        } catch (SQLException e) {
            throw new RuntimeException("Error fetching user stats", e);
        }
    }
}
