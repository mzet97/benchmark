package com.benchmark.service

import com.benchmark.model.User
import com.benchmark.model.ComplexResult
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service
import java.time.LocalDateTime

@Service
class DatabaseService(
    private val jdbcTemplate: JdbcTemplate
) {
    fun getUserById(id: Int): User? {
        val sql = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?"

        return jdbcTemplate.queryForObject(sql, User::class.java, id)
    }

    fun getComplexQuery(days: Int): List<ComplexResult> {
        val sql = """
            SELECT u.id as user_id, u.email as user_email,
                   COUNT(DISTINCT o.id) as total_orders,
                   COALESCE(SUM(o.total_amount), 0) as total_value,
                   COALESCE(AVG(o.total_amount), 0) as average_value,
                   EXTRACT(DAY FROM NOW() - MIN(o.created_at)) as days_since_first_order
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
              AND o.created_at >= NOW() - INTERVAL '$days days'
            GROUP BY u.id, u.email
            HAVING COUNT(DISTINCT o.id) > 0
            ORDER BY total_value DESC
            LIMIT 100
        """

        return jdbcTemplate.query(sql) { rs, _ ->
            ComplexResult(
                userId = rs.getInt("user_id"),
                userEmail = rs.getString("user_email"),
                totalOrders = rs.getLong("total_orders"),
                totalValue = rs.getDouble("total_value"),
                averageValue = rs.getDouble("average_value"),
                daysSinceFirstOrder = rs.getDouble("days_since_first_order")
            )
        }
    }

    fun healthCheck(): Boolean {
        return try {
            jdbcTemplate.queryForObject("SELECT 1", Int::class.java) == 1
        } catch (e: Exception) {
            println("Database health check failed: ${e.message}")
            false
        }
    }
}
