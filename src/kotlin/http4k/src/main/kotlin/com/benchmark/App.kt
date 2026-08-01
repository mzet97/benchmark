package com.benchmark

import org.http4k.core.ContentType
import org.http4k.core.HttpHandler
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.NOT_IMPLEMENTED
import org.http4k.core.Status.Companion.OK
import org.http4k.core.with
import org.http4k.format.Jackson
import org.http4k.lens.Header
import org.http4k.routing.bind
import org.http4k.routing.routes
import org.http4k.server.Netty
import org.http4k.server.asServer

private val JSON = Header.CONTENT_TYPE of ContentType.APPLICATION_JSON

private fun json(body: Any): Response =
    Response(OK).with(JSON).body(Jackson.asFormatString(body))

/**
 * /db/simple, /db/complex and /cache used to answer 200 with hardcoded
 * literals -- a fake user, an empty order list, a made-up cache hit -- while
 * this project declares no PostgreSQL or Redis dependency at all and cannot
 * reach either. Those numbers were not measurements of anything, and next to
 * implementations that really do the query they read as a win.
 *
 * They answer 501 until the data layer actually exists, so the runner records
 * "not implemented" instead of a fabricated result. See docs/ACTION_PLAN.md.
 */
private fun notImplemented(endpoint: String): HttpHandler = { _: Request ->
    Response(NOT_IMPLEMENTED).with(JSON).body(
        Jackson.asFormatString(
            mapOf(
                "error" to "Not Implemented",
                "message" to "$endpoint requires a database and cache client; " +
                    "this implementation has neither",
            )
        )
    )
}

fun main() {
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
            json(linkedMapOf("status" to "healthy", "version" to "1.0.0"))
        },
        "/healthz" bind { _: Request -> json(mapOf("status" to "ok")) },
        // The previous handler interpolated a Kotlin Map into a string, which
        // renders as {id=0, name=User 0} -- not JSON at all, so nothing could
        // parse the response.
        "/json" bind { req: Request -> json(Canonical.response(req.query("n"))) },
        "/db/simple" bind notImplemented("/db/simple"),
        "/db/complex" bind notImplemented("/db/complex"),
        "/cache" bind notImplemented("/cache"),
    )

    val port = System.getenv("PORT")?.toIntOrNull() ?: 8080
    app.asServer(Netty(port)).start()
    println("Server started on http://0.0.0.0:$port")
}
