package benchmark;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Service
public class DatabaseService {

    @Value("${database.url}")
    private String databaseUrl;

    @Value("${database.username:benchmark}")
    private String databaseUsername;

    @Value("${database.password:benchmark}")
    private String databasePassword;

    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(databaseUrl, databaseUsername, databasePassword);
    }

    public String checkHealth() {
        try (Connection conn = getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT 1")) {
            return rs.next() ? "connected" : "error";
        } catch (SQLException e) {
            return "error: " + e.getMessage();
        }
    }

    public Models.User getUser(int id) {
        String sql = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new Models.User(
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
        } catch (SQLException e) {
            throw new RuntimeException("Database error", e);
        }
    }

    public List<Models.UserOrderStats> getComplexOrders(int days) {
        String sql = """
                SELECT
                    u.id AS user_id,
                    u.first_name || ' ' || u.last_name AS user_name,
                    COUNT(o.id) AS total_orders,
                    COALESCE(SUM(o.amount), 0) AS total_value,
                    COALESCE(AVG(o.amount), 0) AS average_order_value
                FROM users u
                LEFT JOIN orders o ON u.id = o.user_id
                    AND o.created_at >= NOW() - INTERVAL '1 day' * ?
                GROUP BY u.id, u.first_name, u.last_name
                ORDER BY total_value DESC
                """;

        List<Models.UserOrderStats> statsList = new ArrayList<>();
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, days);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    statsList.add(new Models.UserOrderStats(
                            rs.getInt("user_id"),
                            rs.getString("user_name"),
                            rs.getInt("total_orders"),
                            rs.getDouble("total_value"),
                            rs.getDouble("average_order_value")
                    ));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Database error", e);
        }

        return statsList;
    }
}
