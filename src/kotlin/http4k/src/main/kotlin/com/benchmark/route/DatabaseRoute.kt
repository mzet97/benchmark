package com.benchmark.route

import com.benchmark.service.DatabaseService
import com.benchmark.model.ComplexResponse
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.OK
import org.http4k.core.Status.Companion.BAD_REQUEST
import org.http4k.core.Status.Companion.NOT_FOUND
import org.http4k.routing.HttpRoutingReceiver

fun databaseRoutes(databaseService: DatabaseService): HttpRoutingReceiver {
    return routes(
        "/db/simple" bind { req: Request ->
            val idParam = req.query("id")
            val id = idParam?.toIntOrNull()

            if (id == null || id <= 0) {
                return@bind Response(BAD_REQUEST).body(
                    """{"error":"Bad Request","message":"id parameter is required and must be a positive number"}"""
                )
            }

            val user = databaseService.getUserById(id)

            if (user == null) {
                return@bind Response(NOT_FOUND).body(
                    """{"error":"Not Found","message":"User with id $id not found"}"""
                )
            }

            println("Database simple query executed for user_id: $id")

            Response(OK).body(
                """{"Id":${user.id},"Name":"${user.name}","Email":"${user.email}","CreatedAt":"${user.createdAt}","IsActive":${user.isActive}}"""
            )
        },
        "/db/complex" bind { req: Request ->
            val daysParam = req.query("days")
            val days = daysParam?.toIntOrNull() ?: 30

            if (days <= 0 || days > 365) {
                return@bind Response(BAD_REQUEST).body(
                    """{"error":"Bad Request","message":"days must be between 1 and 365"}"""
                )
            }

            val results = databaseService.getComplexQuery(days)

            println("Database complex query executed for days: $days")

            val complexResponse = ComplexResponse(
                periodDays = days,
                totalUsers = results.size,
                data = results
            )

            Response(OK).body(
                """{"period_days":${complexResponse.periodDays},"total_users":${complexResponse.totalUsers},"data":${
                    complexResponse.data.joinToString(",", "[", "]") { result ->
                        """{"user_id":${result.userId},"user_email":"${result.userEmail}","total_orders":${result.totalOrders},"total_value":${result.totalValue},"average_value":${result.averageValue},"days_since_first_order":${result.daysSinceFirstOrder}}"""
                    }
                }}"""
            )
        }
    )
}
