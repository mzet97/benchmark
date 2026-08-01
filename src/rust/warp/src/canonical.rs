// Canonical /json payload. See contracts/rest/canonical-payloads.md.
//
// The shape matches JsonItem in contracts/grpc/benchmark.proto and
// type JsonItem in contracts/graphql/schema.graphql, so all three protocols
// serialize the same data.
//
// The previous implementation generated a uuid::Uuid::new_v4() and formatted
// Utc::now() for every item -- 1000 random UUIDs and 1000 timestamp
// formattings per request -- which is work no other implementation did.

use serde_json::{json, Value};

pub const DEFAULT_JSON_ITEMS: usize = 1000;
pub const MAX_JSON_ITEMS: usize = 10_000;
const CANONICAL_CREATED_AT: &str = "2026-01-01T00:00:00Z";

/// Item content is a pure function of the index: no randomness and no
/// wall-clock, so the payload is stable across runs and identical across
/// languages.
pub fn canonical_item(i: usize) -> Value {
    json!({
        "id": i,
        "uuid": format!("00000000-0000-0000-0000-{:012}", i),
        "name": format!("Item {}", i),
        "email": format!("item{}@benchmark.local", i),
        "createdAt": CANONICAL_CREATED_AT,
        "isActive": i % 2 == 0
    })
}

/// Parse `?n=`. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
/// serialization ranking is taken at n=100.
pub fn item_count(raw: Option<&str>) -> usize {
    match raw {
        None => DEFAULT_JSON_ITEMS,
        Some(s) => match s.parse::<usize>() {
            Ok(n) => n.min(MAX_JSON_ITEMS),
            Err(_) => DEFAULT_JSON_ITEMS,
        },
    }
}

pub fn build_items(n: usize) -> Vec<Value> {
    (0..n).map(canonical_item).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn item_matches_contract() {
        let cases = [
            (0usize, r#"{"createdAt":"2026-01-01T00:00:00Z","email":"item0@benchmark.local","id":0,"isActive":true,"name":"Item 0","uuid":"00000000-0000-0000-0000-000000000000"}"#),
            (1, r#"{"createdAt":"2026-01-01T00:00:00Z","email":"item1@benchmark.local","id":1,"isActive":false,"name":"Item 1","uuid":"00000000-0000-0000-0000-000000000001"}"#),
            (999, r#"{"createdAt":"2026-01-01T00:00:00Z","email":"item999@benchmark.local","id":999,"isActive":false,"name":"Item 999","uuid":"00000000-0000-0000-0000-000000000999"}"#),
        ];
        for (id, want) in cases {
            // serde_json::json! preserves insertion order only with the
            // preserve_order feature; to_string on a Map is key-sorted by
            // default, which is exactly the normalization the parity gate uses.
            let got = canonical_item(id).to_string();
            assert_eq!(got, want, "item {} diverges from the payload contract", id);
        }
    }

    #[test]
    fn item_count_honours_query_param() {
        assert_eq!(item_count(None), DEFAULT_JSON_ITEMS);
        assert_eq!(item_count(Some("10")), 10);
        assert_eq!(item_count(Some("100")), 100);
        assert_eq!(item_count(Some("abc")), DEFAULT_JSON_ITEMS);
        assert_eq!(item_count(Some("999999")), MAX_JSON_ITEMS);
    }

    #[test]
    fn build_items_is_deterministic() {
        assert_eq!(
            serde_json::to_string(&build_items(50)).unwrap(),
            serde_json::to_string(&build_items(50)).unwrap(),
            "payload is not deterministic and cannot be parity-hashed"
        );
    }
}
