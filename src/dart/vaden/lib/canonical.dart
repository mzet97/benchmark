/// Canonical /json payload. See contracts/rest/canonical-payloads.md.
///
/// The shape matches JsonItem in contracts/grpc/benchmark.proto and
/// type JsonItem in contracts/graphql/schema.graphql, so all three protocols
/// serialize the same data.
///
/// The previous implementation numbered items from 1, used a `uuid-0001-...`
/// string that is not a UUID at all, named them "User 3", stamped
/// DateTime.now() into createdAt and flagged isActive with `i % 10 != 0`
/// instead of `i % 2 == 0`.
library;

const int defaultJsonItems = 1000;
const int maxJsonItems = 10000;
const String _canonicalCreatedAt = '2026-01-01T00:00:00Z';

/// Item content is a pure function of the index: no randomness and no wall
/// clock, so the payload is stable across runs and identical across languages.
Map<String, Object> canonicalItem(int i) => {
      'id': i,
      'uuid': '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}',
      'name': 'Item $i',
      'email': 'item$i@benchmark.local',
      'createdAt': _canonicalCreatedAt,
      'isActive': i % 2 == 0,
    };

/// Parse `?n=`. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
/// serialization ranking is taken at n=100.
int itemCount(String? raw) {
  if (raw == null || raw.isEmpty) return defaultJsonItems;
  final n = int.tryParse(raw);
  if (n == null || n < 0) return defaultJsonItems;
  return n < maxJsonItems ? n : maxJsonItems;
}

List<Map<String, Object>> buildItems(int n) =>
    List.generate(n, canonicalItem, growable: false);
