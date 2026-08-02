// Canonical /json payload contract.
// See contracts/rest/canonical-payloads.md.
//
// The gRPC and GraphQL item types are generated per implementation -- prost
// structs, juniper objects, async-graphql objects -- so this module exposes
// the field values rather than a type. Every implementation builds its own
// item from the same numbers.
//
// Item content is a pure function of the index: no randomness and no wall
// clock, so the payload is stable across runs and identical across languages
// and protocols.

pub const DEFAULT_JSON_ITEMS: i32 = 1000;
pub const MAX_JSON_ITEMS: i32 = 10_000;

/// Fixed by the contract. Formatting the clock once per item is work no
/// implementation should be timed on.
pub const CANONICAL_CREATED_AT: &str = "2026-01-01T00:00:00Z";

pub fn uuid(i: i32) -> String {
    format!("00000000-0000-0000-0000-{:012}", i)
}

pub fn name(i: i32) -> String {
    format!("Item {}", i)
}

pub fn email(i: i32) -> String {
    format!("item{}@benchmark.local", i)
}

pub fn is_active(i: i32) -> bool {
    i % 2 == 0
}

/// Clamp the requested limit. On a 1 GbE link 1000 items is network-bound,
/// so the serialization ranking is taken at 100.
pub fn item_count(limit: i32) -> i32 {
    if limit <= 0 {
        DEFAULT_JSON_ITEMS
    } else if limit > MAX_JSON_ITEMS {
        MAX_JSON_ITEMS
    } else {
        limit
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fields_match_contract() {
        assert_eq!(uuid(0), "00000000-0000-0000-0000-000000000000");
        assert_eq!(uuid(999), "00000000-0000-0000-0000-000000000999");
        assert_eq!(name(42), "Item 42");
        assert_eq!(email(42), "item42@benchmark.local");
        assert!(is_active(0));
        assert!(!is_active(1));
    }

    #[test]
    fn item_count_clamps() {
        assert_eq!(item_count(0), DEFAULT_JSON_ITEMS);
        assert_eq!(item_count(-1), DEFAULT_JSON_ITEMS);
        assert_eq!(item_count(100), 100);
        assert_eq!(item_count(999_999), MAX_JSON_ITEMS);
    }
}
