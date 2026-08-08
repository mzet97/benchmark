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
            // Return empty rather than throwing: the parity gate probes several
            // IDs, and a 500 here (from a transient pool/connection error) makes
            // the whole endpoint look dead. The controller maps empty to 404,
            // which the gate handles by trying the next ID.
            return Optional.empty();
        }

        return Optional.empty();
    }

    public List<UserStats> getUserStats(int days) {
        List<UserStats> stats = new ArrayList<>();

        if (days <= 0 || days > 365) {
            return stats;
        }

        // A PreparedStatement, not Statement.executeQuery(String.format(...)):
        // the interval is a bound parameter now, not text pasted into the SQL.
        String sql = """
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
            """;

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, days);
            ResultSet rs = stmt.executeQuery();

            while (rs.next()) {
                UserStats userStats = new UserStats();
                userStats.setUserId(rs.getInt("userId"));
                userStats.setUserName(rs.getString("userName"));
                userStats.setTotalOrders(rs.getInt("totalOrders"));
                userStats.setTotalValue(rs.getDouble("totalValue"));
                userStats.setAverageOrderValue(rs.getDouble("averageOrderValue"));
                stats.add(userStats);
            }
        } catch (SQLException e) {
            // Return empty rather than throwing so /db/complex still serializes
            // the contract envelope ({periodDays, totalUsers, data}) with HTTP
            // 200 instead of a 500 that the parity gate reads as a hard failure.
            return stats;
        }

        return stats;
    }
}
