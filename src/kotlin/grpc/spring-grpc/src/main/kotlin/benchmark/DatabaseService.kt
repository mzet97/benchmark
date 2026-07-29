package benchmark

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.springframework.stereotype.Service
import java.sql.Connection
import java.sql.DriverManager
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

    private fun getConnection(): Connection {
        val props = Properties().apply {
           setProperty("user", dbUser)
           setProperty("password", dbPassword)
           setProperty("connectTimeout", "5")
           setProperty("socketTimeout", "10")
        }
        return DriverManager.getConnection(connectionUrl, props)
    }

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
