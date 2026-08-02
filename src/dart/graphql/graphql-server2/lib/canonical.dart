/// Canonical /json payload contract.
/// See contracts/rest/canonical-payloads.md.
///
/// The gRPC and GraphQL item shapes differ per implementation (generated
/// protobuf classes on one side, plain maps on the other), so this library
/// exposes the field values rather than a type.
///
/// Item content is a pure function of the index: no randomness and no wall
/// clock, so the payload is stable across runs and identical across
/// languages and protocols.
library;

const int defaultJsonItems = 1000;
const int maxJsonItems = 10000;

/// Fixed by the contract; formatting the clock per item is not measured work.
const String canonicalCreatedAt = '2026-01-01T00:00:00Z';

String canonicalUuid(int i) =>
    '00000000-0000-0000-0000-${i.toString().padLeft(12, '0')}';

String canonicalName(int i) => 'Item $i';

String canonicalEmail(int i) => 'item$i@benchmark.local';

bool canonicalIsActive(int i) => i % 2 == 0;

/// Clamp the requested limit. On a 1 GbE link 1000 items is network-bound,
/// so the serialization ranking is taken at 100.
int itemCount(int? limit) {
  if (limit == null || limit <= 0) return defaultJsonItems;
  return limit < maxJsonItems ? limit : maxJsonItems;
}
