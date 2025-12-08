package com.benchmark.plugins

import io.ktor.server.application.*
import io.ktor.server.plugins.headresponse.*

fun Application.configureSecurity() {
    install(AutoHeadResponse)
}
