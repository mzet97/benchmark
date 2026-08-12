package benchmark

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.stereotype.Service
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import javax.sql.DataSource
import java.sql.Connection
import java.sql.ResultSet
import java.util.Properties

data class User(
    val id: Int,
    val email: String,
    val firstName: String,
    val lastName: String,
    val age: Int,
    val createdAt: String
)

data class UserOrderStat(
    val userId: Int,
    val userName: String,
    val totalOrders: Int,
    val totalValue: Double,
    val averageOrderValue: Double
)

@Service
class DatabaseService {
    private val host = System.getenv("DB_HOST") ?: "localhost"
    private val port = System.getenv("DB_PORT") ?: "5432"
    private val dbName = System.getenv("DB_NAME") ?: "benchmark"
    private val dbUser = System.getenv("DB_USER") ?: "benchmark"
    private val dbPassword = System.getenv("DB_PASSWORD") ?: "benchmark"

    private val connectionUrl = "jdbc:postgresql://$host:$port/$dbName"

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
            jdbcUrl = connectionUrl
            username = dbUser
            password = dbPassword
            maximumPoolSize = dbPoolMax()
            minimumIdle = dbPoolMax()
            // Preserved from the DriverManager properties this replaced.
            addDataSourceProperty("connectTimeout", "5")
            addDataSourceProperty("socketTimeout", "10")
        })
    }

    private fun getConnection(): Connection = dataSource.connection

    suspend fun healthCheck(): String = withContext(Dispatchers.IO) {
        try {
            getConnection().use { conn ->
                conn.prepareStatement("SELECT 1").use { stmt ->
                    val rs = stmt.executeQuery()
                    if (rs.next()) "connected" else "disconnected"
                }
            }
        } catch (e: Exception) {
            println("Database health check failed: ${e.message}")
            "disconnected"
        }
    }

    suspend fun getUser(id: Int): User? = withContext(Dispatchers.IO) {
        getConnection().use { conn ->
            conn.prepareStatement(
                "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?"
            ).use { stmt ->
                stmt.setInt(1, id)
                val rs = stmt.executeQuery()
                if (rs.next()) {
                    rs.toUser()
                } else {
                    null
                }
            }
        }
    }

    suspend fun getComplexOrders(days: Int): List<UserOrderStat> = withContext(Dispatchers.IO) {
        getConnection().use { conn ->
            conn.prepareStatement(
                """
                SELECT
                    u.id as user_id,
                    u.first_name || ' ' || u.last_name as user_name,
                    COUNT(o.id) as total_orders,
                    COALESCE(SUM(o.total_amount), 0) as total_value,
                    COALESCE(AVG(o.total_amount), 0) as average_order_value
                FROM users u
                LEFT JOIN orders o ON u.id = o.user_id
                    AND o.created_at >= NOW() - INTERVAL '$days days'
                GROUP BY u.id, u.first_name, u.last_name
                HAVING COUNT(o.id) > 0
                ORDER BY total_value DESC
                LIMIT 100
                """.trimIndent()
            ).use { stmt ->
                val rs = stmt.executeQuery()
                val results = mutableListOf<UserOrderStat>()
                while (rs.next()) {
                    results.add(
                        UserOrderStat(
                            userId = rs.getInt("user_id"),
                            userName = rs.getString("user_name") ?: "",
                            totalOrders = rs.getInt("total_orders"),
                            totalValue = rs.getDouble("total_value"),
                            averageOrderValue = rs.getDouble("average_order_value")
                        )
                    )
                }
                results
            }
        }
    }

    private fun ResultSet.toUser(): User = User(
        id = getInt("id"),
        email = getString("email") ?: "",
        firstName = getString("first_name") ?: "",
        lastName = getString("last_name") ?: "",
        age = getInt("age"),
        createdAt = getTimestamp("created_at")?.toInstant().toString()
    )
}
