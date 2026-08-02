package benchmark;

/**
 * Canonical /json payload contract. See contracts/rest/canonical-payloads.md.
 *
 * <p>The gRPC and GraphQL item types are generated per implementation --
 * protobuf builders, DGS records, SmallRye types -- so this class exposes the
 * field values rather than a type.
 *
 * <p>Item content is a pure function of the index: no randomness and no wall
 * clock, so the payload is stable across runs and identical across languages
 * and protocols.
 */
public final class Canonical {

    public static final int DEFAULT_ITEMS = 1000;
    public static final int MAX_ITEMS = 10_000;

    /** Fixed by the contract; formatting the clock per item is not measured work. */
    public static final String CREATED_AT = "2026-01-01T00:00:00Z";

    private Canonical() {
    }

    public static String uuid(int i) {
        String digits = Integer.toString(i);
        StringBuilder sb = new StringBuilder(36).append("00000000-0000-0000-0000-");
        for (int pad = digits.length(); pad < 12; pad++) {
            sb.append('0');
        }
        return sb.append(digits).toString();
    }

    public static String name(int i) {
        return "Item " + i;
    }

    public static String email(int i) {
        return "item" + i + "@benchmark.local";
    }

    public static boolean isActive(int i) {
        return i % 2 == 0;
    }

    /**
     * Clamp the requested limit. On a 1 GbE link 1000 items is network-bound,
     * so the serialization ranking is taken at 100.
     */
    public static int itemCount(Integer limit) {
        if (limit == null || limit <= 0) {
            return DEFAULT_ITEMS;
        }
        return Math.min(limit, MAX_ITEMS);
    }
}
