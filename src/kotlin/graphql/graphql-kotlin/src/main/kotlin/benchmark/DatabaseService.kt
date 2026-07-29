package benchmark

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import java.sql.Connection
import java.sql.DriverManager

@Service
class DatabaseService(
    @Value("\${database.url}") private val databaseUrl: String,
    @Value("\${database.username:benchmark}") private val databaseUsername: String,
    @Value("\${database.password:benchmark}") private val databasePassword: String
) {

    private fun getConnection(): Connection {
        return DriverManager.getConnection(databaseUrl, databaseUsername, databasePassword)
    }

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
