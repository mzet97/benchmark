package benchmark;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.sql.DataSource;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class DatabaseService {

    private final String connectionUrl;
    private final String dbUser;
    private final String dbPassword;

    public DatabaseService() {
        String host = System.getenv().getOrDefault("DB_HOST", "localhost");
        String port = System.getenv().getOrDefault("DB_PORT", "5432");
        String dbName = System.getenv().getOrDefault("DB_NAME", "benchmark");
        this.dbUser = System.getenv().getOrDefault("DB_USER", "benchmark");
        this.dbPassword = System.getenv().getOrDefault("DB_PASSWORD", "benchmark");
        this.connectionUrl = "jdbc:postgresql://" + host + ":" + port + "/" + dbName;
    }

    /**
     * Pool size is part of the benchmark contract, not a per-implementation
     * choice: every implementation reads DB_POOL_MAX from the same ConfigMap so
     * the data access layer stops being a hidden variable in the ranking.
     */
    private static int dbPoolMax() {
        String raw = System.getenv("DB_POOL_MAX");
        if (raw != null) {
            try {
                int n = Integer.parseInt(raw.trim());
                if (n > 0) {
                    return n;
                }
            } catch (NumberFormatException ignored) {
                // fall through to the default
            }
        }
        return 32;
    }

    private volatile DataSource dataSource;

    /**
     * Borrows a connection from a pooled DataSource.
     * <p>
     * This used to return {@code DriverManager.getConnection(...)}, which opens a
     * brand new connection on every call -- and every caller is a per-request
     * path. A JDBC connection to PostgreSQL is not cheap: TCP handshake, startup
     * message, SCRAM-SHA-256 authentication over several round trips, and a forked
     * backend process on the server, for one query. Under the benchmark's 100
     * concurrent connections it also drives the server toward max_connections,
     * where the failure mode stops being slowness and becomes refused connections.
     * <p>
     * The call sites did not change: they already wrap the connection in
     * try-with-resources, which now returns it to the pool instead of closing a
     * socket. Built lazily so it works whether the credentials come from a
     * constructor or from field injection. See docs/ACTION_PLAN.md, Fase 9.10.1.
     */
    private Connection getConnection() throws SQLException {
        DataSource ds = dataSource;
        if (ds == null) {
            synchronized (this) {
                ds = dataSource;
                if (ds == null) {
                    HikariConfig cfg = new HikariConfig();
                    cfg.setJdbcUrl(connectionUrl);
                    cfg.setUsername(dbUser);
                    cfg.setPassword(dbPassword);
                    cfg.setMaximumPoolSize(dbPoolMax());
                    cfg.setMinimumIdle(dbPoolMax());
                    ds = new HikariDataSource(cfg);
                    dataSource = ds;
                }
            }
        }
        return ds.getConnection();
    }

    public String healthCheck() {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT 1");
             ResultSet rs = stmt.executeQuery()) {
            return rs.next() ? "connected" : "disconnected";
        } catch (Exception e) {
            System.err.println("Database health check failed: " + e.getMessage());
            return "disconnected";
        }
    }

    public User getUser(int id) throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                     "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?")) {
            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new User(
                            rs.getInt("id"),
                            rs.getString("email"),
                            rs.getString("first_name"),
                            rs.getString("last_name"),
                            rs.getInt("age"),
                            rs.getTimestamp("created_at") != null
                                    ? rs.getTimestamp("created_at").toInstant().toString()
                                    : ""
                    );
                }
                return null;
            }
        }
    }

    public List<UserOrderStat> getComplexOrders(int days) throws SQLException {
        try (Connection conn = getConnection();
             PreparedStatement stmt = conn.prepareStatement(
                     "SELECT " +
                     "u.id as user_id, " +
                     "u.first_name || ' ' || u.last_name as user_name, " +
                     "COUNT(o.id) as total_orders, " +
                     "COALESCE(SUM(o.total_amount), 0) as total_value, " +
                     "COALESCE(AVG(o.total_amount), 0) as average_order_value " +
                     "FROM users u " +
                     "LEFT JOIN orders o ON u.id = o.user_id " +
                     "AND o.created_at >= NOW() - INTERVAL '" + days + " days' " +
                     "GROUP BY u.id, u.first_name, u.last_name " +
                     "HAVING COUNT(o.id) > 0 " +
                     "ORDER BY total_value DESC " +
                     "LIMIT 100")) {
            try (ResultSet rs = stmt.executeQuery()) {
                List<UserOrderStat> results = new ArrayList<>();
                while (rs.next()) {
                    results.add(new UserOrderStat(
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

    public static class User {
        private final int id;
        private final String email;
        private final String firstName;
        private final String lastName;
        private final int age;
        private final String createdAt;

        public User(int id, String email, String firstName, String lastName, int age, String createdAt) {
            this.id = id;
            this.email = email;
            this.firstName = firstName;
            this.lastName = lastName;
            this.age = age;
            this.createdAt = createdAt;
        }

        public int getId() { return id; }
        public String getEmail() { return email; }
        public String getFirstName() { return firstName; }
        public String getLastName() { return lastName; }
        public int getAge() { return age; }
        public String getCreatedAt() { return createdAt; }
    }

    public static class UserOrderStat {
        private final int userId;
        private final String userName;
        private final int totalOrders;
        private final double totalValue;
        private final double averageOrderValue;

        public UserOrderStat(int userId, String userName, int totalOrders, double totalValue, double averageOrderValue) {
            this.userId = userId;
            this.userName = userName;
            this.totalOrders = totalOrders;
            this.totalValue = totalValue;
            this.averageOrderValue = averageOrderValue;
        }

        public int getUserId() { return userId; }
        public String getUserName() { return userName; }
        public int getTotalOrders() { return totalOrders; }
        public double getTotalValue() { return totalValue; }
        public double getAverageOrderValue() { return averageOrderValue; }
    }
}
