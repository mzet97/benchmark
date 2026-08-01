package com.benchmark.services

import com.benchmark.models.UserOrderStats
import com.benchmark.models.User
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.URI

class DatabaseService {
    private val dataSource: HikariDataSource

    init {
        val databaseUrl = System.getenv("DATABASE_URL") ?: error("DATABASE_URL is required")

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
            // Pool size is part of the benchmark contract: every implementation
            // reads DB_POOL_MAX from the same ConfigMap.
            val poolMax = System.getenv("DB_POOL_MAX")?.toIntOrNull() ?: 32
            maximumPoolSize = poolMax
            minimumIdle = poolMax
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
                            age = rs.getInt("age").takeUnless { rs.wasNull() },
                            createdAt = rs.getTimestamp("created_at").toString()
                        )
                    } else null
                }
            }
        }
    }

    suspend fun findComplexOrders(days: Int): List<UserOrderStats> = withContext(Dispatchers.IO) {
        val query = """
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
        """.trimIndent()

        val results = mutableListOf<UserOrderStats>()
        dataSource.connection.use { conn ->
            conn.prepareStatement(query).use { stmt ->
                stmt.setInt(1, days)
                stmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        results.add(UserOrderStats(
                            userId = rs.getInt("userId"),
                            userName = rs.getString("userName"),
                            totalOrders = rs.getLong("totalOrders"),
                            totalValue = rs.getDouble("totalValue"),
                            averageOrderValue = rs.getDouble("averageOrderValue")
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
