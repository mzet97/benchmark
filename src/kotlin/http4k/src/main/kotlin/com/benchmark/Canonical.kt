package com.benchmark

import java.time.Instant

/**
 * Canonical /json payload. See contracts/rest/canonical-payloads.md.
 *
 * The shape matches JsonItem in contracts/grpc/benchmark.proto and
 * type JsonItem in contracts/graphql/schema.graphql, so all three protocols
 * serialize the same data.
 *
 * linkedMapOf, not mapOf: iteration order of the default map is not part of
 * its contract, and the payload has to be byte-stable across runs.
 */
object Canonical {

    const val DEFAULT_ITEMS = 1000
    const val MAX_ITEMS = 10_000
    private const val CANONICAL_CREATED_AT = "2026-01-01T00:00:00Z"

    /**
     * Item content is a pure function of the index: no randomness and no wall
     * clock, so the payload is stable across runs and identical across
     * languages.
     */
    fun item(i: Int): Map<String, Any> = linkedMapOf(
        "id" to i,
        "uuid" to uuid(i),
        "name" to "Item $i",
        "email" to "item$i@benchmark.local",
        "createdAt" to CANONICAL_CREATED_AT,
        "isActive" to (i % 2 == 0),
    )

    private fun uuid(i: Int): String =
        "00000000-0000-0000-0000-" + i.toString().padStart(12, '0')

    /**
     * Parse `?n=`. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
     * serialization ranking is taken at n=100.
     */
    fun itemCount(raw: String?): Int {
        if (raw.isNullOrEmpty()) return DEFAULT_ITEMS
        val n = raw.toIntOrNull() ?: return DEFAULT_ITEMS
        return if (n < 0) DEFAULT_ITEMS else minOf(n, MAX_ITEMS)
    }

    fun build(n: Int): List<Map<String, Any>> = (0 until n).map { item(it) }

    /**
     * Envelope for /json. The timestamp is the only clock-dependent field and
     * is excluded from the parity hash.
     */
    fun response(raw: String?): Map<String, Any> {
        val n = itemCount(raw)
        return linkedMapOf(
            "items" to build(n),
            "count" to n,
            "timestamp" to Instant.now().toString(),
        )
    }
}
