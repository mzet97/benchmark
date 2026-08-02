package com.benchmark

import org.http4k.core.ContentType
import org.http4k.core.HttpHandler
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.BAD_REQUEST
import org.http4k.core.Status.Companion.NOT_FOUND
import org.http4k.core.Status.Companion.OK
import org.http4k.core.with
import org.http4k.format.Jackson
import org.http4k.lens.Header
import org.http4k.routing.bind
import org.http4k.routing.routes
import org.http4k.server.Netty
import org.http4k.server.asServer
import java.time.Instant

// The explicit type is required: `of` returns a modifier generic in the message
// type, and hoisting it into a val leaves nothing to infer it from.
private val JSON: (Response) -> Response =
    Header.CONTENT_TYPE of ContentType.APPLICATION_JSON

private fun json(body: Any): Response =
    Response(OK).with(JSON).body(Jackson.asFormatString(body))

private fun errorJson(status: org.http4k.core.Status, message: String): Response =
    Response(status).with(JSON).body(
        Jackson.asFormatString(linkedMapOf("error" to status.description, "message" to message))
    )

// The TTL is part of the response contract and must match what is written to
// Redis. See contracts/rest/canonical-payloads.md.
private const val CACHE_TTL_SECONDS = 300L

fun main() {
    // /db/simple, /db/complex and /cache used to answer 200 with hardcoded
    // literals -- a fake user, an empty order list, a made-up cache hit --
    // because this project declared no PostgreSQL or Redis dependency and could
    // not reach either. They then answered 501 so the runner would record "not
    // implemented" rather than a fabricated win. They now run the same queries
    // as every other implementation. See docs/ACTION_PLAN.md, Fase 3.
    val db = Db()
    val cache = Cache()

    Runtime.getRuntime().addShutdownHook(Thread {
        db.close()
        cache.close()
    })

    val app: HttpHandler = routes(
        "/" bind { _: Request ->
            json(
                linkedMapOf(
                    "name" to "Benchmark API - Kotlin http4k",
                    "version" to "1.0.0",
                    "runtime" to "JVM",
                    "framework" to "http4k",
                    "status" to "running",
                )
            )
        },
        "/health" bind { _: Request ->
            json(
                linkedMapOf(
                    "status" to "ok",
                    "version" to "1.0.0",
                    "timestamp" to Instant.now().toString(),
                    // "connected"/"disconnected", as in the src/go/fiber
                    // reference. The gate checks the key set here, not the
                    // values, but there is no reason to differ.
                    "database" to if (db.healthy()) "connected" else "disconnected",
                    "cache" to if (cache.healthy()) "connected" else "disconnected",
                )
            )
        },
        "/healthz" bind { _: Request -> json(mapOf("status" to "ok")) },
        // The previous handler interpolated a Kotlin Map into a string, which
        // renders as {id=0, name=User 0} -- not JSON at all, so nothing could
        // parse the response.
        "/json" bind { req: Request -> json(Canonical.response(req.query("n"))) },

        "/db/simple" bind { req: Request ->
            val id = req.query("id")?.toIntOrNull() ?: 1
            db.findUserById(id)
                ?.let { json(it) }
                ?: errorJson(NOT_FOUND, "User with id $id not found")
        },

        "/db/complex" bind { req: Request ->
            val days = req.query("days")?.toIntOrNull() ?: 30
            if (days <= 0 || days > 365) {
                errorJson(BAD_REQUEST, "days must be between 1 and 365")
            } else {
                val data = db.findComplexOrders(days)
                json(
                    linkedMapOf(
                        "periodDays" to days,
                        "totalUsers" to data.size,
                        "data" to data,
                    )
                )
            }
        },

        "/cache" bind { req: Request ->
            val key = req.query("key") ?: "test"
            val hit = cache.get(key)
            val value = hit ?: "cached-value-$key-${System.currentTimeMillis()}"
            if (hit == null) cache.set(key, value, CACHE_TTL_SECONDS)
            json(
                linkedMapOf(
                    "key" to key,
                    "value" to value,
                    "cached" to (hit != null),
                    "ttl" to CACHE_TTL_SECONDS.toInt(),
                    "timestamp" to Instant.now().toString(),
                )
            )
        },
    )

    val port = System.getenv("PORT")?.toIntOrNull() ?: 8080
    app.asServer(Netty(port)).start()
    println("Server started on http://0.0.0.0:$port")
}
