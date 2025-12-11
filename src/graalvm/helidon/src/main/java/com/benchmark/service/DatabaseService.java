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
                 """)) {
            stmt.setInt(1, days);
            stmt.setInt(2, days);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                UserStats stat = new UserStats(
                    rs.getInt("user_id"),
                    rs.getString("user_name"),
                    rs.getInt("total_orders"),
                    rs.getDouble("total_value"),
                    rs.getDouble("average_value")
                );
                stats.add(stat);
            }

            return stats;
        } catch (SQLException e) {
            throw new RuntimeException("Error fetching user stats", e);
        }
    }
}
