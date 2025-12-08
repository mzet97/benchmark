package com.benchmark.routes

import com.benchmark.models.JsonItem
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.jsonRoutes() {
    route("/json") {
        get {
            val items = (0 until 1000).map { JsonItem.create(it) }

            val response = mapOf(
                "items" to items,
                "count" to items.size,
                "timestamp" to items[0].timestamp
            )

            call.respond(HttpStatusCode.OK, response)
        }
    }
}
