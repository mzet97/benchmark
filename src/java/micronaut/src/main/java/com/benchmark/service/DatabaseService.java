package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import javax.sql.DataSource;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Singleton
public class DatabaseService {
    private final DataSource dataSource;

    @Inject
    public DatabaseService(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Optional<User> getUserById(Integer id) {
        if (id == null) {
            return Optional.empty();
        }

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                 "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?")) {
            stmt.setInt(1, id);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                User user = new User();
                user.setId(rs.getInt("id"));
                user.setEmail(rs.getString("email"));
                user.setFirstName(rs.getString("first_name"));
                user.setLastName(rs.getString("last_name"));
                user.setAge(rs.getObject("age", Integer.class));
                user.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
                return Optional.of(user);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error fetching user", e);
        }

        return Optional.empty();
    }

    public List<UserStats> getUserStats(int days) {
        List<UserStats> stats = new ArrayList<>();

        if (days <= 0 || days > 365) {
            throw new IllegalArgumentException("Days must be between 1 and 365");
        }

        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            ResultSet rs = stmt.executeQuery(String.format("""
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

            while (rs.next()) {
                UserStats userStats = new UserStats();
                userStats.setUserId(rs.getInt("user_id"));
                userStats.setUserName(rs.getString("user_name"));
                userStats.setTotalOrders(rs.getInt("total_orders"));
                userStats.setTotalValue(rs.getDouble("total_value"));
                userStats.setAverageValue(rs.getDouble("average_value"));
                stats.add(userStats);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error fetching user stats", e);
        }

        return stats;
    }
}
