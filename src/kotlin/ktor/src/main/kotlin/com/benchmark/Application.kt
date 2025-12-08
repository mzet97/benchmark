package com.benchmark

import com.benchmark.plugins.*
import com.benchmark.routes.*
import com.benchmark.services.CacheService
import com.benchmark.services.DatabaseService
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import org.slf4j.LoggerFactory

fun main() {
    val port = System.getenv("PORT")?.toIntOrNull() ?: 8080
    val host = "0.0.0.0"

    val logger = LoggerFactory.getLogger("BenchmarkKtor")

    embeddedServer(Netty, port = port, host = host) {
        module(dbService = DatabaseService(), cacheService = CacheService())
    }.start(wait = true)
}

fun Application.module(
    dbService: DatabaseService,
    cacheService: CacheService
) {
    // Configure plugins
    configureSerialization()
    configureMonitoring()
    configureHTTP()
    configureCORS()
    configureSecurity()
    configureStatusPages()

    // Configure routing
    routing {
        healthRoutes(dbService, cacheService)
        jsonRoutes()
        databaseRoutes(dbService)
        cacheRoutes(cacheService)
    }

    // Add shutdown hook
    Runtime.getRuntime().addShutdownHook(Thread {
        dbService.close()
        cacheService.close()
    })
}
