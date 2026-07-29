package benchmark;

import benchmark.Benchmark.*;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DatabaseService {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseService.class);
    private final HikariDataSource dataSource;

    public DatabaseService() {
        String dbUrl = System.getenv().getOrDefault("DATABASE_URL", "jdbc:postgresql://localhost:5432/benchmark");
        String dbUser = System.getenv().getOrDefault("DB_USER", "benchmark");
        String dbPassword = System.getenv().getOrDefault("DB_PASSWORD", "benchmark");

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(dbUrl);
        config.setUsername(dbUser);
        config.setPassword(dbPassword);
        config.setMaximumPoolSize(25);
        config.setMinimumIdle(5);
        config.setDriverClassName("org.postgresql.Driver");

        this.dataSource = new HikariDataSource(config);
        logger.info("Database connection pool initialized");
    }

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

    public void close() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
            logger.info("Database connection pool closed");
        }
    }
}
