package benchmark

/**
 * Canonical /json payload contract. See contracts/rest/canonical-payloads.md.
 *
 * The gRPC and GraphQL item types are generated per implementation, so this
 * object exposes the field values rather than a type.
 *
 * Item content is a pure function of the index: no randomness and no wall
 * clock, so the payload is stable across runs and identical across languages
 * and protocols.
 */
object Canonical {

    const val DEFAULT_ITEMS = 1000
    const val MAX_ITEMS = 10_000

    /** Fixed by the contract; formatting the clock per item is not measured work. */
    const val CREATED_AT = "2026-01-01T00:00:00Z"

    fun uuid(i: Int): String = "00000000-0000-0000-0000-" + i.toString().padStart(12, '0')

    fun name(i: Int): String = "Item $i"

    fun email(i: Int): String = "item$i@benchmark.local"

    fun isActive(i: Int): Boolean = i % 2 == 0

    /**
     * Clamp the requested limit. On a 1 GbE link 1000 items is network-bound,
     * so the serialization ranking is taken at 100.
     */
    fun itemCount(limit: Int?): Int {
        if (limit == null || limit <= 0) return DEFAULT_ITEMS
        return minOf(limit, MAX_ITEMS)
    }
}
