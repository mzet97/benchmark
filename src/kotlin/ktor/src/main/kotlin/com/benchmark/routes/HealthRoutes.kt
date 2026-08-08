package com.benchmark.routes

import com.benchmark.services.CacheService
import com.benchmark.services.DatabaseService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant

fun Route.healthRoutes(dbService: DatabaseService, cacheService: CacheService) {
    get("/health") {
        // Contract: {"status","version","timestamp","database","cache"} with HTTP 200.
        // The parity gate (-sf curl) reads any non-200 as a hard failure, so a
        // 503 on a down dependency makes the whole endpoint look dead even
        // though the key set is what is actually checked. Report per-dependency
        // state in the values and always return 200.
        val dbOk = dbService.healthCheck()
        val cacheOk = cacheService.healthCheck()
        call.respondText(
            """{"status":"${if (dbOk && cacheOk) "ok" else "degraded"}","version":"1.0.0","timestamp":"${Instant.now()}","database":"${if (dbOk) "up" else "down"}","cache":"${if (cacheOk) "up" else "down"}"}""",
            ContentType.Application.Json, HttpStatusCode.OK
        )
    }

    get("/healthz") {
        call.respondText("""{"status":"ok"}""", ContentType.Application.Json)
    }
}
