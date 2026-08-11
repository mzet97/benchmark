package benchmark;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import javax.sql.DataSource;
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
     * brand new connection on every call -- and every caller below is a
     * per-request path. A JDBC connection to PostgreSQL is not cheap: TCP
     * handshake, startup message, SCRAM-SHA-256 authentication over several round
     * trips, and a forked backend process on the server, for one query. Under the
     * benchmark's 100 concurrent connections it also pushes the server toward
     * max_connections, where the failure mode stops being slowness and becomes
     * refused connections.
     * <p>
     * The call sites did not change: they already wrap the connection in
     * try-with-resources, which now returns it to the pool instead of closing a
     * socket. HikariCP is already on the classpath here (via
     * spring-boot-starter-data-jdbc / micronaut-jdbc-hikari), so this needs no new
     * dependency.
     * <p>
     * Built lazily because the {@code @Value} fields above are injected after
     * construction. See docs/ACTION_PLAN.md, Fase 9.10.
     */
    private Connection getConnection() throws SQLException {
        DataSource ds = dataSource;
        if (ds == null) {
            synchronized (this) {
                ds = dataSource;
                if (ds == null) {
                    HikariConfig cfg = new HikariConfig();
                    cfg.setJdbcUrl(databaseUrl);
                    cfg.setUsername(databaseUsername);
                    cfg.setPassword(databasePassword);
                    cfg.setMaximumPoolSize(dbPoolMax());
                    cfg.setMinimumIdle(dbPoolMax());
                    ds = new HikariDataSource(cfg);
                    dataSource = ds;
                }
            }
        }
        return ds.getConnection();
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
