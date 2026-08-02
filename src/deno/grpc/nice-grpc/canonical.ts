// Canonical /json payload contract.
// See contracts/rest/canonical-payloads.md.
//
// The gRPC and GraphQL item shapes differ per implementation (snake_case on
// the proto side, camelCase on the GraphQL side), so this module exposes the
// field values rather than a whole object.
//
// Item content is a pure function of the index: no randomness and no wall
// clock, so the payload is stable across runs and identical across languages
// and protocols.

export const DEFAULT_ITEMS = 1000;
export const MAX_ITEMS = 10000;

// Fixed by the contract. Reading or formatting the clock once per item is
// work no implementation should be timed on.
export const CANONICAL_CREATED_AT = '2026-01-01T00:00:00Z';

export function canonicalUuid(i: number): string {
  return `00000000-0000-0000-0000-${String(i).padStart(12, '0')}`;
}

export function canonicalName(i: number): string {
  return `Item ${i}`;
}

export function canonicalEmail(i: number): string {
  return `item${i}@benchmark.local`;
}

export function canonicalIsActive(i: number): boolean {
  return i % 2 === 0;
}

// Clamp the requested limit. On a 1 GbE link 1000 items is network-bound, so
// the serialization ranking is taken at 100.
export function itemCount(limit: unknown): number {
  const n = Number(limit);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_ITEMS;
  return Math.min(Math.trunc(n), MAX_ITEMS);
}
