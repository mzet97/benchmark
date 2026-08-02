package com.benchmark

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource

/**
 * PostgreSQL access for the http4k implementation.
 *
 * This project used to declare no database dependency at all: /db/simple
 * answered 200 with an invented user and /db/complex with an empty order list.
 * See docs/ACTION_PLAN.md, Fase 3.
 *
 * Pool sizing, connection string parsing and SQL are deliberately identical to
 * src/kotlin/ktor -- an implementation that runs a different query is not
 * measuring the same thing, however similar the response looks.
 */
class Db {
    private val dataSource: HikariDataSource

    init {
        val databaseUrl = System.getenv("DATABASE_URL") ?: error("DATABASE_URL is required")

        // Parse postgresql://user:password@host:port/database, splitting at the
        // last @ so a password containing one still parses.
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

        val config = HikariConfig().apply {
            jdbcUrl = "jdbc:postgresql://$host:$port/$database"
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

    /**
     * Normative SQL, see contracts/rest/canonical-payloads.md. The aliases are
     * double-quoted so Postgres returns camelCase column names.
     */
    fun findUserById(id: Int): Map<String, Any?>? {
        val sql = """
            SELECT id, email, first_name AS "firstName", last_name AS "lastName",
                   age, created_at AS "createdAt"
            FROM users
            WHERE id = ?
        """.trimIndent()

        dataSource.connection.use { conn ->
            conn.prepareStatement(sql).use { stmt ->
                stmt.setInt(1, id)
                stmt.executeQuery().use { rs ->
                    if (!rs.next()) return null
                    val age = rs.getInt("age").takeUnless { rs.wasNull() }
                    return linkedMapOf(
                        "id" to rs.getInt("id"),
                        "email" to rs.getString("email"),
                        "firstName" to rs.getString("firstName"),
                        "lastName" to rs.getString("lastName"),
                        "age" to age,
                        "createdAt" to rs.getTimestamp("createdAt").toString(),
                    )
                }
            }
        }
    }

    /**
     * Normative SQL. The interval is a bound parameter, the ORDER BY has a
     * tiebreak so equal aggregates come back in a reproducible order, and the
     * LIMIT is part of the contract: changing it changes the payload size and
     * therefore the network ceiling.
     */
    fun findComplexOrders(days: Int): List<Map<String, Any>> {
        val sql = """
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

        val rows = mutableListOf<Map<String, Any>>()
        dataSource.connection.use { conn ->
            conn.prepareStatement(sql).use { stmt ->
                stmt.setInt(1, days)
                stmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        rows.add(
                            linkedMapOf(
                                "userId" to rs.getInt("userId"),
                                "userName" to rs.getString("userName"),
                                "totalOrders" to rs.getLong("totalOrders"),
                                "totalValue" to rs.getDouble("totalValue"),
                                "averageOrderValue" to rs.getDouble("averageOrderValue"),
                            )
                        )
                    }
                }
            }
        }
        return rows
    }

    fun healthy(): Boolean = try {
        dataSource.connection.use { conn ->
            conn.prepareStatement("SELECT 1").use { stmt ->
                stmt.executeQuery().use { rs -> rs.next() && rs.getInt(1) == 1 }
            }
        }
    } catch (e: Exception) {
        false
    }

    fun close() = dataSource.close()
}
