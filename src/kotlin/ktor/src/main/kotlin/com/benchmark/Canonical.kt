package com.benchmark

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.Instant

/**
 * Canonical /json payload. See contracts/rest/canonical-payloads.md.
 *
 * The shape matches JsonItem in contracts/grpc/benchmark.proto and
 * type JsonItem in contracts/graphql/schema.graphql, so all three protocols
 * serialize the same data.
 *
 * These are @Serializable classes rather than maps so the payload goes
 * through the same kotlinx.serialization path the rest of the app uses. The
 * previous implementation concatenated the JSON by hand into a StringBuilder,
 * which measured string building instead of the serializer every other
 * implementation was being measured on -- and it minted a UUID.randomUUID()
 * per item on top of that.
 */
@Serializable
data class JsonItem(
    val id: Int,
    val uuid: String,
    val name: String,
    val email: String,
    @SerialName("createdAt") val createdAt: String,
    @SerialName("isActive") val isActive: Boolean,
)

@Serializable
data class JsonResponse(
    val items: List<JsonItem>,
    val count: Int,
    val timestamp: String,
)

object Canonical {

    const val DEFAULT_ITEMS = 1000
    const val MAX_ITEMS = 10_000
    private const val CANONICAL_CREATED_AT = "2026-01-01T00:00:00Z"

    /**
     * Item content is a pure function of the index: no randomness and no wall
     * clock, so the payload is stable across runs and identical across
     * languages.
     */
    fun item(i: Int): JsonItem = JsonItem(
        id = i,
        uuid = "00000000-0000-0000-0000-" + i.toString().padStart(12, '0'),
        name = "Item $i",
        email = "item$i@benchmark.local",
        createdAt = CANONICAL_CREATED_AT,
        isActive = i % 2 == 0,
    )

    /**
     * Parse `?n=`. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
     * serialization ranking is taken at n=100.
     */
    fun itemCount(raw: String?): Int {
        if (raw.isNullOrEmpty()) return DEFAULT_ITEMS
        val n = raw.toIntOrNull() ?: return DEFAULT_ITEMS
        return if (n < 0) DEFAULT_ITEMS else minOf(n, MAX_ITEMS)
    }

    fun build(n: Int): List<JsonItem> = (0 until n).map { item(it) }

    /**
     * Envelope for /json. The timestamp is the only clock-dependent field and
     * is excluded from the parity hash.
     */
    fun response(raw: String?): JsonResponse {
        val n = itemCount(raw)
        return JsonResponse(items = build(n), count = n, timestamp = Instant.now().toString())
    }
}
