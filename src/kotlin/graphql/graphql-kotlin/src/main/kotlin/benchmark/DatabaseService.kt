package benchmark

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import javax.sql.DataSource
import java.sql.Connection

@Service
class DatabaseService(
    @Value("\${database.url}") private val databaseUrl: String,
    @Value("\${database.username:benchmark}") private val databaseUsername: String,
    @Value("\${database.password:benchmark}") private val databasePassword: String
) {

    /**
     * Pool size is part of the benchmark contract, not a per-implementation
     * choice: every implementation reads DB_POOL_MAX from the same ConfigMap so
     * the data access layer stops being a hidden variable in the ranking.
     */
    private fun dbPoolMax(): Int =
        System.getenv("DB_POOL_MAX")?.trim()?.toIntOrNull()?.takeIf { it > 0 } ?: 32

    /**
     * Pooled DataSource, built on first access.
     *
     * getConnection() used to return DriverManager.getConnection(...), which opens
     * a brand new connection on every call -- and every caller is a per-request
     * path. A JDBC connection to PostgreSQL costs a TCP handshake, a startup
     * message, SCRAM-SHA-256 authentication over several round trips and a forked
     * backend process on the server, for one query. Under the benchmark's 100
     * concurrent connections it also drives the server toward max_connections,
     * where the failure mode stops being slowness and becomes refused connections.
     *
     * `by lazy` rather than an initializer because the credentials arrive by field
     * injection on the Spring variants, after construction. The call sites did not
     * change: they already wrap the connection in use()/try-with-resources, which
     * now returns it to the pool instead of closing a socket.
     * See docs/ACTION_PLAN.md, Fase 9.10.1.
     */
    private val dataSource: DataSource by lazy {
        HikariDataSource(HikariConfig().apply {
            jdbcUrl = databaseUrl
            username = databaseUsername
            password = databasePassword
            maximumPoolSize = dbPoolMax()
            minimumIdle = dbPoolMax()
        })
    }

    private fun getConnection(): Connection = dataSource.connection

    fun checkHealth(): Boolean {
        return try {
            getConnection().use { conn ->
                conn.createStatement().use { stmt ->
                    stmt.executeQuery("SELECT 1").use { rs ->
                        rs.next()
                    }
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    fun getUser(userId: Int): User? {
        val sql = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?"
        return getConnection().use { conn ->
            conn.prepareStatement(sql).use { stmt ->
                stmt.setInt(1, userId)
                stmt.executeQuery().use { rs ->
                    if (rs.next()) {
                        User(
                            id = rs.getInt("id"),
                            email = rs.getString("email"),
                            firstName = rs.getString("first_name"),
                            lastName = rs.getString("last_name"),
                            age = rs.getInt("age"),
                            createdAt = rs.getTimestamp("created_at").toInstant().toString()
                        )
                    } else null
                }
            }
        }
    }

    fun getComplexOrders(days: Int): List<UserOrderStats> {
        val sql = """
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
        """.trimIndent()

        return getConnection().use { conn ->
            conn.prepareStatement(sql).use { stmt ->
                stmt.setInt(1, days)
                stmt.executeQuery().use { rs ->
                    val results = mutableListOf<UserOrderStats>()
                    while (rs.next()) {
                        results.add(UserOrderStats(
                            userId = rs.getInt("user_id"),
                            userName = rs.getString("user_name"),
                            totalOrders = rs.getInt("total_orders"),
                            totalValue = rs.getDouble("total_value"),
                            averageOrderValue = rs.getDouble("average_order_value")
                        ))
                    }
                    results
                }
            }
        }
    }
}
