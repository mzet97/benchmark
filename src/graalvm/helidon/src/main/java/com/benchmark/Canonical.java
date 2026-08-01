package com.benchmark;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Canonical /json payload. See contracts/rest/canonical-payloads.md.
 *
 * <p>The shape matches JsonItem in contracts/grpc/benchmark.proto and
 * type JsonItem in contracts/graphql/schema.graphql, so all three protocols
 * serialize the same data.
 *
 * <p>LinkedHashMap, not Map.of: Map.of iterates in an unspecified order that
 * varies per JVM run, so two runs of the same implementation produced
 * different byte streams. Plain maps also keep this class reflection-free,
 * which matters for the GraalVM native-image builds.
 */
public final class Canonical {

    public static final int DEFAULT_ITEMS = 1000;
    public static final int MAX_ITEMS = 10_000;
    private static final String CANONICAL_CREATED_AT = "2026-01-01T00:00:00Z";

    private Canonical() {
    }

    /**
     * Item content is a pure function of the index: no randomness and no wall
     * clock, so the payload is stable across runs and identical across
     * languages.
     */
    public static Map<String, Object> item(int i) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", i);
        item.put("uuid", uuid(i));
        item.put("name", "Item " + i);
        item.put("email", "item" + i + "@benchmark.local");
        item.put("createdAt", CANONICAL_CREATED_AT);
        item.put("isActive", i % 2 == 0);
        return item;
    }

    private static String uuid(int i) {
        String digits = Integer.toString(i);
        StringBuilder sb = new StringBuilder(36);
        sb.append("00000000-0000-0000-0000-");
        for (int pad = digits.length(); pad < 12; pad++) {
            sb.append('0');
        }
        return sb.append(digits).toString();
    }

    /**
     * Parse {@code ?n=}. On a 1 GbE link n=1000 is network-bound at ~734 rps,
     * so the serialization ranking is taken at n=100.
     */
    public static int itemCount(String raw) {
        if (raw == null || raw.isEmpty()) {
            return DEFAULT_ITEMS;
        }
        try {
            int n = Integer.parseInt(raw);
            return n < 0 ? DEFAULT_ITEMS : Math.min(n, MAX_ITEMS);
        } catch (NumberFormatException e) {
            return DEFAULT_ITEMS;
        }
    }

    public static List<Map<String, Object>> build(int n) {
        List<Map<String, Object>> items = new ArrayList<>(n);
        for (int i = 0; i < n; i++) {
            items.add(item(i));
        }
        return items;
    }

    /**
     * Envelope for /json. The timestamp is the only clock-dependent field and
     * is excluded from the parity hash.
     */
    public static Map<String, Object> response(String rawCount) {
        int n = itemCount(rawCount);
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("items", build(n));
        response.put("count", n);
        response.put("timestamp", Instant.now().toString());
        return response;
    }
}
