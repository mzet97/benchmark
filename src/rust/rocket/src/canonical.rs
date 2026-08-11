// Canonical /json payload. See contracts/rest/canonical-payloads.md.
//
// The shape matches JsonItem in contracts/grpc/benchmark.proto and
// type JsonItem in contracts/graphql/schema.graphql, so all three protocols
// serialize the same data.
//
// The previous implementation generated a uuid::Uuid::new_v4() and formatted
// Utc::now() for every item -- 1000 random UUIDs and 1000 timestamp
// formattings per request -- which is work no other implementation did.

use serde::Serialize;

pub const DEFAULT_JSON_ITEMS: usize = 1000;
pub const MAX_JSON_ITEMS: usize = 10_000;
const CANONICAL_CREATED_AT: &str = "2026-01-01T00:00:00Z";

/// One item, serialized straight into the response buffer.
///
/// This used to be a `serde_json::json!{}` per item, i.e. a
/// `Map<String, Value>` (a BTreeMap) with six heap-allocated keys and three
/// `format!` values -- roughly ten thousand allocations to answer /json?n=1000,
/// plus a dynamic tree walk at serialization time. That is why actix-web led
/// the n=10 scenario at 211,970 rps and then finished eleventh at n=1000 with
/// 5,226 rps while emitting the same ~150 kB payload as implementations doing
/// 2-4x better. A `Serialize` struct writes its fields directly with no
/// intermediate representation.
///
/// Field order here is the field order on the wire. serde emits struct fields
/// in declaration order while `json!` produced BTreeMap-sorted keys, so the
/// declaration order below is alphabetical to keep the bytes identical to what
/// the parity gate hashed before. The gate normalizes anyway
/// (scripts/validate-parity.py), but matching byte-for-byte keeps the payload
/// size comparison honest.
#[derive(Serialize)]
pub struct CanonicalItem {
    #[serde(rename = "createdAt")]
    created_at: &'static str,
    email: String,
    id: usize,
    #[serde(rename = "isActive")]
    is_active: bool,
    name: String,
    uuid: String,
}

/// Item content is a pure function of the index: no randomness and no
/// wall-clock, so the payload is stable across runs and identical across
/// languages.
pub fn canonical_item(i: usize) -> CanonicalItem {
    CanonicalItem {
        created_at: CANONICAL_CREATED_AT,
        email: format!("item{i}@benchmark.local"),
        id: i,
        is_active: i % 2 == 0,
        name: format!("Item {i}"),
        uuid: format!("00000000-0000-0000-0000-{i:012}"),
    }
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

pub fn build_items(n: usize) -> Vec<CanonicalItem> {
    (0..n).map(canonical_item).collect()
}

/// The /json response envelope.
///
/// This has to be a struct rather than a `json!{}` wrapper: passing
/// `build_items(n)` into `json!` calls `serde_json::to_value` on the Vec, which
/// rebuilds every item as a `Value` tree and throws away the whole point of
/// serializing the items from a struct. Keeping the envelope typed means the
/// response goes from the items straight to the socket buffer.
///
/// Fields are alphabetical for the same wire-compatibility reason as
/// `CanonicalItem`.
#[derive(Serialize)]
pub struct JsonEnvelope {
    pub count: usize,
    pub items: Vec<CanonicalItem>,
    pub timestamp: String,
}

/// `timestamp` is the only clock-dependent field in the payload and is excluded
/// from the parity hash.
pub fn envelope(n: usize) -> JsonEnvelope {
    JsonEnvelope {
        count: n,
        items: build_items(n),
        timestamp: chrono::Utc::now().to_rfc3339(),
    }
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
            // The struct declares its fields in alphabetical order, which
            // reproduces the key-sorted output the previous Map-backed Value
            // produced -- and which is the normalization the parity gate uses.
            let got = serde_json::to_string(&canonical_item(id)).unwrap();
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

    /// The envelope must serialize its keys in the same order the previous
    /// `json!{}` implementation did (Map = BTreeMap, so key-sorted), otherwise
    /// the payload the parity gate hashed changes for reasons that have nothing
    /// to do with the framework.
    #[test]
    fn envelope_key_order_matches_contract() {
        let got = serde_json::to_string(&envelope(1)).unwrap();
        assert!(
            got.starts_with(r#"{"count":1,"items":[{"createdAt":"#),
            "envelope key order diverges from the payload contract: {got}"
        );
        // timestamp is the only clock-dependent field and comes last.
        assert!(got.contains(r#"],"timestamp":"#), "envelope shape changed: {got}");
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
