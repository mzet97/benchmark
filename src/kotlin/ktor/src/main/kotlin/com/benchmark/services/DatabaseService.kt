package com.benchmark.services

import com.benchmark.models.ComplexOrderResult
import com.benchmark.models.User
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.sql.Connection
import java.sql.ResultSet
import java.time.LocalDateTime

class DatabaseService {
    private val dataSource: HikariDataSource

    init {
        val dbUrl = System.getenv("DATABASE_URL") ?: "jdbc:postgresql://spsql.home.arpa:5432/benchmark_api"
        val dbUser = System.getenv("DATABASE_USER") ?: "app"
        val dbPassword = System.getenv("DATABASE_PASSWORD") ?: "Admin@123"

        val config = HikariConfig().apply {
            jdbcUrl = dbUrl
            username = dbUser
            password = dbPassword
            driverClassName = "org.postgresql.Driver"
            maximumPoolSize = 25
            minimumIdle = 5
            connectionTimeout = 5000
            idleTimeout = 600000
            maxLifetime = 1800000
        }

        dataSource = HikariDataSource(config)
    }

    suspend fun findUserById(id: Int): User? = withContext(Dispatchers.IO) {
        val query = """
            SELECT id, email, first_name, last_name, age, created_at
            FROM users
            WHERE id = ?
        """.trimIndent()

        dataSource.connection.use { conn ->
            conn.prepareStatement(query).use { stmt ->
                stmt.setInt(1, id)
                stmt.executeQuery().use { rs ->
                    if (rs.next()) {
                        User(
                            id = rs.getInt("id"),
                            email = rs.getString("email"),
                            firstName = rs.getString("first_name"),
                            lastName = rs.getString("last_name"),
                            age = rs.getInt("age"),
                            createdAt = rs.getTimestamp("created_at").toString()
                        )
                    } else {
                        null
                    }
                }
            }
        }
    }

    suspend fun findComplexOrders(days: Int): List<ComplexOrderResult> = withContext(Dispatchers.IO) {
        val query = """
            SELECT
                u.id as user_id,
                u.email,
                COUNT(o.id) as order_count,
                SUM(o.total_amount) as total_amount,
                AVG(o.total_amount) as avg_amount,
                EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
            WHERE o.created_at >= NOW() - (? || ' days')::INTERVAL
            GROUP BY u.id, u.email
            ORDER BY order_count DESC
            LIMIT 100
        """.trimIndent()

        val results = mutableListOf<ComplexOrderResult>()

        dataSource.connection.use { conn ->
            conn.prepareStatement(query).use { stmt ->
                stmt.setInt(1, days)
                stmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        results.add(
                            ComplexOrderResult(
                                userId = rs.getInt("user_id"),
                                email = rs.getString("email"),
                                orderCount = rs.getLong("order_count"),
                                totalAmount = rs.getDouble("total_amount"),
                                averageAmount = rs.getDouble("avg_amount"),
                                daysSinceFirstOrder = rs.getLong("days_since_first_order")
                            )
                        )
                    }
                }
            }
        }

        results
    }

    suspend fun healthCheck(): Boolean = withContext(Dispatchers.IO) {
        try {
            dataSource.connection.use { conn ->
                conn.prepareStatement("SELECT 1").use { stmt ->
                    stmt.executeQuery().use { rs ->
                        rs.next() && rs.getInt(1) == 1
                    }
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    fun close() {
        dataSource.close()
    }
}
