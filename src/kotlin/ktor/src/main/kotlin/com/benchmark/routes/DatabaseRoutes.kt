package com.benchmark.routes

import com.benchmark.services.DatabaseService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant

fun Route.databaseRoutes(dbService: DatabaseService) {
    route("/db") {
        get("/simple") {
            val idParam = call.request.queryParameters["id"]
            val id = idParam?.toIntOrNull() ?: 1

            val user = dbService.findUserById(id)

            if (user != null) {
                val response = mapOf(
                    "user" to user,
                    "timestamp" to Instant.now().toString()
                )
                call.respond(HttpStatusCode.OK, response)
            } else {
                val error = mapOf(
                    "error" to "User not found",
                    "id" to id
                )
                call.respond(HttpStatusCode.NotFound, error)
            }
        }

        get("/complex") {
            val daysParam = call.request.queryParameters["days"]
            val days = daysParam?.toIntOrNull() ?: 30

            val orders = dbService.findComplexOrders(days)

            val response = mapOf(
                "orders" to orders,
                "count" to orders.size,
                "days" to days,
                "timestamp" to Instant.now().toString()
            )

            call.respond(HttpStatusCode.OK, response)
        }
    }
}
