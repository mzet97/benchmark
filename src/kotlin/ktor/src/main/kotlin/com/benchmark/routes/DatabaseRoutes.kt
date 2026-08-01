package com.benchmark.routes

import com.benchmark.models.UserOrderStats
import com.benchmark.services.DatabaseService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.Serializable

// Both handlers used to concatenate their JSON by hand into a StringBuilder or
// a template string, with snake_case keys and an {user_id, email, order_count,
// total_amount, average_amount} shape nothing else emitted. They now go
// through the same kotlinx.serialization path as the rest of the app.
// See contracts/rest/canonical-payloads.md.

@Serializable
private data class ComplexResponse(
    val periodDays: Int,
    val totalUsers: Int,
    val data: List<UserOrderStats>,
)

@Serializable
private data class ErrorResponse(val error: String)

fun Route.databaseRoutes(dbService: DatabaseService) {
    get("/db/simple") {
        val id = call.request.queryParameters["id"]?.toIntOrNull() ?: 1
        val user = dbService.findUserById(id)
        if (user != null) {
            call.respond(user)
        } else {
            call.respond(HttpStatusCode.NotFound, ErrorResponse("User with id $id not found"))
        }
    }

    get("/db/complex") {
        val days = call.request.queryParameters["days"]?.toIntOrNull() ?: 30
        if (days <= 0 || days > 365) {
            call.respond(HttpStatusCode.BadRequest, ErrorResponse("days must be between 1 and 365"))
            return@get
        }
        val data = dbService.findComplexOrders(days)
        call.respond(ComplexResponse(periodDays = days, totalUsers = data.size, data = data))
    }
}
