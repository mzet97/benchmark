package com.benchmark.route

import org.http4k.core.Request
import org.http4k.core.Response
import org.http4k.core.Status.Companion.OK
import org.http4k.routing.HttpRoutingReceiver

fun jsonRoutes(): HttpRoutingReceiver {
    return routes(
        "/json" bind { _: Request ->
            val items = (0..999).map { """{"id":$it,"name":"User $it","email":"user$it@example.com","active":true,"tags":["benchmark","test","api"]}""" }
                .joinToString(",", "[", "]")
            Response(OK).body("""{"items":$items,"count":${items.split(",").size},"timestamp":"${java.time.Instant.now()}"}""")
        }
    )
}
