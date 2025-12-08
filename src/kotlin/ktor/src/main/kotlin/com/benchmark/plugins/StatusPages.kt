package com.benchmark.plugins

import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.response.*

fun Application.configureStatusPages() {
    install(StatusPages) {
        exception<Throwable> { call, cause ->
            call.respond(
                HttpStatusCode.InternalServerError,
                mapOf(
                    "error" to cause.message ?: "Internal Server Error",
                    "status" to "error"
                )
            )
        }
        status(HttpStatusCode.NotFound) { call, status ->
            call.respond(
                status,
                mapOf(
                    "error" to "Not Found",
                    "status" to "error",
                    "code" to status.value
                )
            )
        }
    }
}
