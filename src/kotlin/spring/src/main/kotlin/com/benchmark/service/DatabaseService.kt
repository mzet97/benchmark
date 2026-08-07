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
        val sql = """
            SELECT id, email, first_name AS "firstName", last_name AS "lastName",
                   age, created_at AS "createdAt"
            FROM users
            WHERE id = ?
        """

        val users = jdbcTemplate.query(sql, { rs, _ ->
            User(
                id = rs.getInt("id"),
                email = rs.getString("email"),
                firstName = rs.getString("firstName"),
                lastName = rs.getString("lastName"),
                age = rs.getObject("age") as? Int,
                createdAt = rs.getTimestamp("createdAt").toLocalDateTime()
            )
        }, id)

        return users.firstOrNull()
    }

    fun getComplexQuery(days: Int): List<ComplexResult> {
        val sql = """
            -- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
            -- query joined order_items, aggregated quantity*price and ordered without
            -- a tiebreak, so it ran a heavier query than the other implementations and
            -- its rows came back in arbitrary order among equal values.
            SELECT
                u.id AS "userId",
                u.first_name || ' ' || u.last_name AS "userName",
                COUNT(o.id) AS "totalOrders",
                COALESCE(SUM(o.total_amount), 0) AS "totalValue",
                COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
                WHERE o.created_at >= NOW() - INTERVAL '1 day' * ?
            GROUP BY u.id, u.first_name, u.last_name
            ORDER BY "totalOrders" DESC, u.id
            LIMIT 100
        """

        return jdbcTemplate.query(sql, { rs, _ ->
            ComplexResult(
                userId = rs.getInt("userId"),
                userName = rs.getString("userName"),
                totalOrders = rs.getLong("totalOrders"),
                totalValue = rs.getDouble("totalValue"),
                averageOrderValue = rs.getDouble("averageOrderValue")
            )
        }, days)
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
