package com.benchmark.routes

import com.benchmark.services.DatabaseService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant

fun Route.databaseRoutes(dbService: DatabaseService) {
    get("/db/simple") {
        val id = call.request.queryParameters["id"]?.toIntOrNull() ?: 1
        val user = dbService.findUserById(id)
        if (user != null) {
            call.respondText(
                """{"id":${user.id},"email":"${user.email}","first_name":"${user.firstName}","last_name":"${user.lastName}","age":${user.age},"created_at":"${user.createdAt}"}""",
                ContentType.Application.Json
            )
        } else {
            call.respondText("""{"error":"User with id $id not found"}""", ContentType.Application.Json, HttpStatusCode.NotFound)
        }
    }

    get("/db/complex") {
        val days = call.request.queryParameters["days"]?.toIntOrNull() ?: 30
        val orders = dbService.findComplexOrders(days)
        val sb = StringBuilder()
        sb.append("{\"period_days\":$days,\"total_users\":${orders.size},\"data\":[")
        orders.forEachIndexed { i, o ->
            if (i > 0) sb.append(",")
            sb.append("{\"user_id\":${o.userId},\"email\":\"${o.email}\",\"order_count\":${o.orderCount},\"total_amount\":${o.totalAmount},\"average_amount\":${o.averageAmount}}")
        }
        sb.append("],\"timestamp\":\"${Instant.now()}\"}")
        call.respondText(sb.toString(), ContentType.Application.Json)
    }
}
