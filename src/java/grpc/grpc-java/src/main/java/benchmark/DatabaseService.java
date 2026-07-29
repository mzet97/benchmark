package benchmark;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class DatabaseService {

    private final String jdbcUrl;
    private final Properties props;

    public DatabaseService() {
        String host = System.getenv().getOrDefault("DB_HOST", "localhost");
        String port = System.getenv().getOrDefault("DB_PORT", "5432");
        String dbName = System.getenv().getOrDefault("DB_NAME", "benchmark");
        String user = System.getenv().getOrDefault("DB_USER", "benchmark");
        String password = System.getenv().getOrDefault("DB_PASSWORD", "benchmark");

        this.jdbcUrl = String.format("jdbc:postgresql://%s:%s/%s", host, port, dbName);
        this.props = new Properties();
        this.props.setProperty("user", user);
        this.props.setProperty("password", password);
    }

    public String checkHealth() {
        try (Connection conn = DriverManager.getConnection(jdbcUrl, props)) {
            conn.isValid(5);
            return "connected";
        } catch (SQLException e) {
            return "disconnected";
        }
    }

    public UserRecord getUser(int id) throws SQLException {
        try (Connection conn = DriverManager.getConnection(jdbcUrl, props);
             PreparedStatement stmt = conn.prepareStatement(
                     "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?")) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new UserRecord(
                            rs.getInt("id"),
                            rs.getString("email"),
                            rs.getString("first_name"),
                            rs.getString("last_name"),
                            rs.getInt("age"),
                            rs.getTimestamp("created_at").toInstant().toString()
                    );
                }
                return null;
            }
        }
    }

    public List<UserOrderStatsRecord> getComplexOrders(int days) throws SQLException {
        try (Connection conn = DriverManager.getConnection(jdbcUrl, props);
             PreparedStatement stmt = conn.prepareStatement(
                     "SELECT u.id AS user_id, " +
                             "u.first_name || ' ' || u.last_name AS user_name, " +
                             "COUNT(o.id) AS total_orders, " +
                             "COALESCE(SUM(o.total_amount), 0) AS total_value, " +
                             "COALESCE(AVG(o.total_amount), 0) AS average_order_value " +
                             "FROM users u " +
                             "LEFT JOIN orders o ON u.id = o.user_id " +
                             "AND o.created_at >= NOW() - (? || ' days')::INTERVAL " +
                             "GROUP BY u.id, u.first_name, u.last_name " +
                             "ORDER BY total_value DESC")) {
            stmt.setString(1, String.valueOf(days));
            try (ResultSet rs = stmt.executeQuery()) {
                List<UserOrderStatsRecord> results = new ArrayList<>();
                while (rs.next()) {
                    results.add(new UserOrderStatsRecord(
                            rs.getInt("user_id"),
                            rs.getString("user_name"),
                            rs.getInt("total_orders"),
                            rs.getDouble("total_value"),
                            rs.getDouble("average_order_value")
                    ));
                }
                return results;
            }
        }
    }

    public static class UserRecord {
        public final int id;
        public final String email;
        public final String firstName;
        public final String lastName;
        public final int age;
        public final String createdAt;

        public UserRecord(int id, String email, String firstName, String lastName, int age, String createdAt) {
            this.id = id;
            this.email = email;
            this.firstName = firstName;
            this.lastName = lastName;
            this.age = age;
            this.createdAt = createdAt;
        }
    }

    public static class UserOrderStatsRecord {
        public final int userId;
        public final String userName;
        public final int totalOrders;
        public final double totalValue;
        public final double averageOrderValue;

        public UserOrderStatsRecord(int userId, String userName, int totalOrders, double totalValue, double averageOrderValue) {
            this.userId = userId;
            this.userName = userName;
            this.totalOrders = totalOrders;
            this.totalValue = totalValue;
            this.averageOrderValue = averageOrderValue;
        }
    }
}
