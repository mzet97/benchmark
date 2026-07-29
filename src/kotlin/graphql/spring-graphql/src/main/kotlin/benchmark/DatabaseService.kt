package benchmark

import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service

@Service
class DatabaseService(private val jdbcTemplate: JdbcTemplate) {

    fun checkHealth(): Boolean {
        return try {
            jdbcTemplate.queryForObject("SELECT 1", Int::class.java) != null
            true
        } catch (e: Exception) {
            false
        }
    }

    fun getUser(userId: Int): User? {
        val results = jdbcTemplate.query(
            "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?",
            arrayOf(userId)
        ) { rs, _ ->
            User(
                id = rs.getInt("id"),
                email = rs.getString("email"),
                firstName = rs.getString("first_name"),
                lastName = rs.getString("last_name"),
                age = rs.getInt("age"),
                createdAt = rs.getTimestamp("created_at").toInstant().toString()
            )
        }
        return results.firstOrNull()
    }

    fun getComplexOrders(days: Int): List<UserOrderStats> {
        return jdbcTemplate.query(
            """
            SELECT
                u.id as user_id,
                CONCAT(u.first_name, ' ', u.last_name) as user_name,
                COUNT(DISTINCT o.id) as total_orders,
                COALESCE(SUM(o.total_amount), 0) as total_value,
                COALESCE(AVG(o.total_amount), 0) as average_order_value
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
                AND o.created_at >= NOW() - make_interval(days => ?)
                AND o.status = 'completed'
            LEFT JOIN order_items oi ON o.id = oi.order_id
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY total_value DESC
            LIMIT 100
            """.trimIndent(),
            arrayOf(days)
        ) { rs, _ ->
            UserOrderStats(
                userId = rs.getInt("user_id"),
                userName = rs.getString("user_name"),
                totalOrders = rs.getInt("total_orders"),
                totalValue = rs.getDouble("total_value"),
                averageOrderValue = rs.getDouble("average_order_value")
            )
        }
    }
}
