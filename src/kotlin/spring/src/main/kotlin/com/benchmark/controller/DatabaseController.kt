package com.benchmark.controller

import com.benchmark.service.DatabaseService
import com.benchmark.model.ComplexResponse
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.Instant

@RestController
class DatabaseController(
    private val databaseService: DatabaseService
) {
    @GetMapping("/db/simple")
    fun dbSimple(@RequestParam(defaultValue = "1") id: Int): Map<String, Any> {
        if (id <= 0) {
            return mapOf(
                "error" to "Bad Request",
                "message" to "id must be a positive number"
            )
        }

        val user = databaseService.getUserById(id)

        return if (user != null) {
            println("Database simple query executed for user_id: $id")
            mapOf(
                "id" to user.id,
                "email" to user.email,
                "firstName" to user.firstName,
                "lastName" to user.lastName,
                "age" to (user.age ?: 0),
                "createdAt" to user.createdAt.toString()
            )
        } else {
            mapOf(
                "id" to id,
                "email" to "",
                "firstName" to "",
                "lastName" to "",
                "age" to 0,
                "createdAt" to ""
            )
        }
    }

    @GetMapping("/db/complex")
    fun dbComplex(@RequestParam(defaultValue = "30") days: Int): Map<String, Any> {
        if (days <= 0 || days > 365) {
            return mapOf(
                "error" to "Bad Request",
                "message" to "days must be between 1 and 365"
            )
        }

        val results = databaseService.getComplexQuery(days)

        println("Database complex query executed for days: $days")

        return mapOf(
            "periodDays" to days,
            "totalUsers" to results.size,
            "data" to results
        )
    }
}
