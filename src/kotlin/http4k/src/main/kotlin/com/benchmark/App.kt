package com.benchmark

import org.http4k.core.HttpHandler
import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.OK
import org.http4k.routing.bind
import org.http4k.routing.routes
import org.http4k.server.Netty
import org.http4k.server.asServer

fun main() {
    val app: HttpHandler = routes(
        "/" bind { _: Request -> Response(OK).body("""{"name":"Benchmark API - Kotlin http4k","version":"1.0.0","status":"running"}""") },
        "/health" bind { _: Request -> Response(OK).body("""{"status":"healthy","version":"1.0.0"}""") },
        "/json" bind { _: Request -> 
            val items = (0..999).map { mapOf("id" to it, "name" to "User $it") }
            Response(OK).body("""{"items":$items,"count":${items.size}}""")
        },
        "/db/simple" bind { _: Request -> Response(OK).body("""{"user":{"id":1,"name":"John Doe"}}""") },
        "/db/complex" bind { _: Request -> Response(OK).body("""{"orders":[]}""") },
        "/cache" bind { _: Request -> Response(OK).body("""{"key":"test","value":"cached-value-test","source":"generated"}""") }
    )
    
    app.asServer(Netty(3000)).start()
    println("Server started on http://localhost:3000")
}
