package com.benchmark.routes

import com.benchmark.Canonical

import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.jsonRoutes() {
    get("/json") {
        call.respond(Canonical.response(call.request.queryParameters["n"]))
    }
}
