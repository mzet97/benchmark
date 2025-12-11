package com.benchmark.service

import com.benchmark.model.User
import com.benchmark.model.ComplexResult
import java.sql.Connection
import java.sql.DriverManager
import java.sql.ResultSet
import java.time.LocalDateTime

class DatabaseService {
    private var connection: Connection? = null

    fun init() {
        try {
            val url = System.getenv("DATABASE_URL") ?: "jdbc:postgresql://spsql.home.arpa:5432/benchmark_api"
            val user = "app"
            val password = "Admin@123"

            connection = DriverManager.getConnection(url, user, password)
            println("✅ Database connection established")
        } catch (e: Exception) {
            println("❌ Failed to connect to database: ${e.message}")
            throw e
        }
    }

    fun getUserById(id: Int): User? {
        val conn = connection ?: throw IllegalStateException("Database not initialized")

        val sql = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?"
        conn.prepareStatement(sql).use { stmt ->
            stmt.setInt(1, id)
            stmt.executeQuery().use { rs ->
                return if (rs.next()) {
                    User(
                        id = rs.getInt("id"),
                        email = rs.getString("email"),
                        firstName = rs.getString("first_name"),
                        lastName = rs.getString("last_name"),
                        age = rs.getObject("age", Int::class.java),
                        createdAt = rs.getTimestamp("created_at").toLocalDateTime()
                    )
                } else null
            }
        }
    }

    fun getComplexQuery(days: Int): List<ComplexResult> {
        val conn = connection ?: throw IllegalStateException("Database not initialized")

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

        val results = mutableListOf<ComplexResult>()
        conn.createStatement().use { stmt ->
            stmt.executeQuery(sql).use { rs ->
                while (rs.next()) {
                    results.add(
                        ComplexResult(
                            userId = rs.getInt("user_id"),
                            userEmail = rs.getString("user_email"),
                            totalOrders = rs.getLong("total_orders"),
                            totalValue = rs.getDouble("total_value"),
                            averageValue = rs.getDouble("average_value"),
                            daysSinceFirstOrder = rs.getDouble("days_since_first_order")
                        )
                    )
                }
            }
        }
        return results
    }

    fun healthCheck(): Boolean {
        return try {
            val conn = connection ?: return false
            conn.createStatement().use { stmt ->
                stmt.execute("SELECT 1")
            }
            true
        } catch (e: Exception) {
            println("Database health check failed: ${e.message}")
            false
        }
    }

    fun close() {
        connection?.close()
        connection = null
        println("✅ Database connection closed")
    }
}
