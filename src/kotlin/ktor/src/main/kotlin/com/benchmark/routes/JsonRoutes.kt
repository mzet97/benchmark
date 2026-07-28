package com.benchmark.routes

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant
import java.util.UUID

fun Route.jsonRoutes() {
    get("/json") {
        val timestamp = Instant.now().toString()
        val sb = StringBuilder()
        sb.append("{\"items\":[")
        for (i in 0 until 1000) {
            if (i > 0) sb.append(",")
            sb.append("{\"id\":$i,\"name\":\"Item $i\",\"description\":\"This is item number $i\",\"timestamp\":\"$timestamp\",\"random\":\"data-${UUID.randomUUID()}\"}")
        }
        sb.append("],\"count\":1000,\"timestamp\":\"$timestamp\"}")
        call.respondText(sb.toString(), ContentType.Application.Json)
    }
}
