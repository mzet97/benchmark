package com.benchmark.controller

import com.benchmark.service.DatabaseService
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException

@RestController
class DatabaseController(
    private val databaseService: DatabaseService
) {
    // Error paths throw ResponseStatusException instead of returning a body with
    // 200. Every branch below used to answer 200: a bad `id` returned
    // {"error": "Bad Request", ...} with a success status, and an id that does
    // not exist returned a *fabricated* user with empty strings and age 0.
    //
    // That last one is the worst of the three, because it is undetectable from
    // the outside. It passes scripts/validate-parity.py -- the key set is
    // exactly right -- and it passes the load generator, which counts a 200. A
    // reader of the ranking cannot distinguish this implementation answering the
    // question from it inventing an answer. Invariante 8 in docs/ACTION_PLAN.md.
    //
    // Throwing keeps the `Map<String, Any>` return type: Spring MVC maps the
    // exception to the status and body, so no handler signature changes.
    @GetMapping("/db/simple")
    fun dbSimple(@RequestParam(defaultValue = "1") id: Int): Map<String, Any> {
        if (id <= 0) {
            throw ResponseStatusException(
                HttpStatus.BAD_REQUEST, "id must be a positive number"
            )
        }

        // No println per request: a synchronized stdout write on the measured
        // path, in a blocking servlet model. Invariante 1 in
        // docs/ACTION_PLAN.md, and the reason
        // deploy/k3s/base/configmap.yaml sets LOG_LEVEL=error.
        val user = databaseService.getUserById(id)
            ?: throw ResponseStatusException(
                HttpStatus.NOT_FOUND, "User with id $id not found"
            )

        return mapOf(
            "id" to user.id,
            "email" to user.email,
            "firstName" to user.firstName,
            "lastName" to user.lastName,
            "age" to (user.age ?: 0),
            "createdAt" to user.createdAt.toString()
        )
    }

    @GetMapping("/db/complex")
    fun dbComplex(@RequestParam(defaultValue = "30") days: Int): Map<String, Any> {
        if (days <= 0 || days > 365) {
            throw ResponseStatusException(
                HttpStatus.BAD_REQUEST, "days must be between 1 and 365"
            )
        }

        val results = databaseService.getComplexQuery(days)

        // No println per request -- see dbSimple above.
        return mapOf(
            "periodDays" to days,
            "totalUsers" to results.size,
            "data" to results
        )
    }
}
