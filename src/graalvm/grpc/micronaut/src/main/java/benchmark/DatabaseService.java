package benchmark;

import benchmark.Benchmark.*;
import io.micronaut.context.annotation.Value;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Singleton
public class DatabaseService {

    @Inject
    private DataSource dataSource;

    public boolean isConnected() {
        try (Connection conn = dataSource.getConnection()) {
            return conn.isValid(5);
        } catch (SQLException e) {
            return false;
        }
    }

    public UserResponse getUser(int id) throws SQLException {
        String sql = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, id);

            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return UserResponse.newBuilder()
                            .setId(rs.getInt("id"))
                            .setEmail(rs.getString("email"))
                            .setFirstName(rs.getString("first_name"))
                            .setLastName(rs.getString("last_name"))
                            .setAge(rs.getInt("age"))
                            .setCreatedAt(rs.getTimestamp("created_at").toInstant().toString())
                            .build();
                }
                return UserResponse.getDefaultInstance();
            }
        }
    }

    public ComplexOrdersResponse getComplexOrders(int days) throws SQLException {
        String sql = """
                SELECT
                    u.id AS user_id,
                    u.first_name || ' ' || u.last_name AS user_name,
                    COUNT(o.id) AS total_orders,
                    COALESCE(SUM(o.total_amount), 0) AS total_value,
                    COALESCE(AVG(o.total_amount), 0) AS average_order_value
                FROM users u
                LEFT JOIN orders o ON u.id = o.user_id
                    AND o.created_at >= NOW() - INTERVAL '1 day' * ?
                GROUP BY u.id, u.first_name, u.last_name
                ORDER BY total_value DESC
                LIMIT 100
                """;

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setInt(1, days);

            try (ResultSet rs = stmt.executeQuery()) {
                ComplexOrdersResponse.Builder builder = ComplexOrdersResponse.newBuilder();
                builder.setPeriodDays(days);

                List<UserOrderStats> statsList = new ArrayList<>();
                while (rs.next()) {
                    statsList.add(UserOrderStats.newBuilder()
                            .setUserId(rs.getInt("user_id"))
                            .setUserName(rs.getString("user_name"))
                            .setTotalOrders(rs.getInt("total_orders"))
                            .setTotalValue(rs.getDouble("total_value"))
                            .setAverageOrderValue(rs.getDouble("average_order_value"))
                            .build());
                }

                builder.setTotalUsers(statsList.size());
                builder.addAllData(statsList);
                return builder.build();
            }
        }
    }
}
