// Canonical /json payload. See contracts/rest/canonical-payloads.md.
//
// The shape matches JsonItem in contracts/grpc/benchmark.proto and
// type JsonItem in contracts/graphql/schema.graphql, so all three protocols
// serialize the same data.
export const DEFAULT_ITEMS = 1000;
export const MAX_ITEMS = 10000;
const CANONICAL_CREATED_AT = '2026-01-01T00:00:00Z';

// Item content is a pure function of the index: no randomness and no
// wall-clock, so the payload is stable across runs and identical across
// languages.
export function canonicalItem(i) {
  return {
    id: i,
    uuid: `00000000-0000-0000-0000-${String(i).padStart(12, '0')}`,
    name: `Item ${i}`,
    email: `item${i}@benchmark.local`,
    createdAt: CANONICAL_CREATED_AT,
    isActive: i % 2 === 0,
  };
}

// Parse ?n=. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
// serialization ranking is taken at n=100.
export function itemCount(raw) {
  if (raw === undefined || raw === null || raw === '') return DEFAULT_ITEMS;
  const n = Number.parseInt(raw, 10);
  if (Number.isNaN(n) || n < 0) return DEFAULT_ITEMS;
  return Math.min(n, MAX_ITEMS);
}

export function buildItems(n) {
  const items = new Array(n);
  for (let i = 0; i < n; i++) items[i] = canonicalItem(i);
  return items;
}

// Kept for backwards compatibility with the existing import site.
export const createJsonItem = canonicalItem;

export function validateJsonItem(data) {
  return typeof data.id === 'number' &&
         typeof data.uuid === 'string' &&
         typeof data.name === 'string' &&
         typeof data.email === 'string' &&
         typeof data.createdAt === 'string' &&
         typeof data.isActive === 'boolean';
}
