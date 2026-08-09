package com.benchmark.service;

import com.benchmark.model.User;
import com.benchmark.model.UserStats;
import io.micronaut.context.annotation.Primary;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Reads {@code users}/{@code orders} over raw JDBC.
 *
 * <p>These two queries used to live in a Micronaut Data
 * {@code @JdbcRepository} ({@code UserRepository}). The
 * {@code micronaut-data-processor} implements a repository interface at
 * compile time by introspecting the entity, which requires the return type to
 * carry {@code @MappedEntity} (+ {@code @Id}). {@code User}/{@code UserStats}
 * are plain Jackson serialization DTOs with no JPA-style mapping on purpose
 * (every other implementation here maps rows by hand), so the processor aborted
 * the build with "Could not resolve root entity" for {@code findByIdRaw}.
 * Rather than pollute the DTOs with Micronaut Data annotations, the queries are
 * executed here against the {@code default} {@link DataSource} produced by
 * {@link com.benchmark.config.DatasourceFactory}. The SQL is byte-for-byte the
 * normative query from {@code contracts/rest/canonical-payloads.md}.
 */
@Singleton
@Primary
public class DatabaseService {
    private final DataSource dataSource;

    @Inject
    public DatabaseService(@Named("default") DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Optional<User> getUserById(Integer id) {
        final String sql = "SELECT id, email, first_name, last_name, age, created_at "
            + "FROM users WHERE id = ?";
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                return Optional.of(mapUser(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("Failed to fetch user " + id, e);
        }
    }

    public List<UserStats> getUserStats(Integer days) {
        // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
        // query joined order_items, aggregated quantity*price and ordered without
        // a tiebreak, so it ran a heavier query than the other implementations and
        // its rows came back in arbitrary order among equal values.
        final String sql = """
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
        List<UserStats> result = new ArrayList<>();
        try (Connection conn = dataSource.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, days);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapUserStats(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Failed to fetch user stats for days=" + days, e);
        }
        return result;
    }

    private static User mapUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getInt("id"));
        user.setEmail(rs.getString("email"));
        user.setFirstName(rs.getString("first_name"));
        user.setLastName(rs.getString("last_name"));
        user.setAge(rs.getInt("age"));
        Timestamp createdAt = rs.getTimestamp("created_at");
        user.setCreatedAt(createdAt == null ? null : createdAt.toLocalDateTime());
        return user;
    }

    private static UserStats mapUserStats(ResultSet rs) throws SQLException {
        return new UserStats(
            rs.getInt("userId"),
            rs.getString("userName"),
            rs.getInt("totalOrders"),
            rs.getDouble("totalValue"),
            rs.getDouble("averageOrderValue")
        );
    }
}
