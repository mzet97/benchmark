package com.benchmark.services

import com.benchmark.models.ComplexOrderResult
import com.benchmark.models.User
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URI

class DatabaseService {
    private val dataSource: HikariDataSource

    init {
        val databaseUrl = System.getenv("DATABASE_URL") ?: "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api"

        // Parse postgresql://user:password@host:port/database
        // Handle @ in password by splitting from last @
        val lastAt = databaseUrl.lastIndexOf('@')
        val schemeEnd = databaseUrl.indexOf("://")
        val userPass = databaseUrl.substring(schemeEnd + 3, lastAt)
        val hostPortDb = databaseUrl.substring(lastAt + 1)
        val user = userPass.substringBefore(':')
        val password = userPass.substringAfter(':')
        val host = hostPortDb.substringBefore(':')
        val portDb = hostPortDb.substringAfter(':')
        val port = portDb.substringBefore('/').toIntOrNull() ?: 5432
        val database = portDb.substringAfter('/')

        val jdbcUrl = "jdbc:postgresql://$host:$port/$database"

        val config = HikariConfig().apply {
            this.jdbcUrl = jdbcUrl
            username = user
            this.password = password
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
        val query = "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = ?"
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
                    } else null
                }
            }
        }
    }

    suspend fun findComplexOrders(days: Int): List<ComplexOrderResult> = withContext(Dispatchers.IO) {
        val query = """
            SELECT u.id as user_id, u.email,
                   COUNT(o.id) as order_count,
                   COALESCE(SUM(o.total_amount), 0) as total_amount,
                   COALESCE(AVG(o.total_amount), 0) as avg_amount,
                   EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
            FROM users u
            INNER JOIN orders o ON u.id = o.user_id
            WHERE o.created_at >= NOW() - INTERVAL '1 day' * ?
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
                        results.add(ComplexOrderResult(
                            userId = rs.getInt("user_id"),
                            email = rs.getString("email"),
                            orderCount = rs.getLong("order_count"),
                            totalAmount = rs.getDouble("total_amount"),
                            averageAmount = rs.getDouble("avg_amount"),
                            daysSinceFirstOrder = rs.getLong("days_since_first_order")
                        ))
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
                    stmt.executeQuery().use { rs -> rs.next() && rs.getInt(1) == 1 }
                }
            }
        } catch (e: Exception) { false }
    }

    fun close() { dataSource.close() }
}
