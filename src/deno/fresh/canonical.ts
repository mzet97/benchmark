// Canonical /json payload. See contracts/rest/canonical-payloads.md.
//
// The shape matches JsonItem in contracts/grpc/benchmark.proto and
// type JsonItem in contracts/graphql/schema.graphql, so all three protocols
// serialize the same data.
//
// The previous implementation numbered items from 1 and generated two
// crypto.randomUUID() values per item -- 2000 random UUIDs per request --
// which is work no other implementation did.

export interface JsonItem {
  id: number;
  uuid: string;
  name: string;
  email: string;
  createdAt: string;
  isActive: boolean;
}

export const DEFAULT_ITEMS = 1000;
export const MAX_ITEMS = 10000;
const CANONICAL_CREATED_AT = "2026-01-01T00:00:00Z";

// Item content is a pure function of the index: no randomness and no
// wall-clock, so the payload is stable across runs and identical across
// languages.
export function canonicalItem(i: number): JsonItem {
  return {
    id: i,
    uuid: `00000000-0000-0000-0000-${String(i).padStart(12, "0")}`,
    name: `Item ${i}`,
    email: `item${i}@benchmark.local`,
    createdAt: CANONICAL_CREATED_AT,
    isActive: i % 2 === 0,
  };
}

// Parse ?n=. On a 1 GbE link n=1000 is network-bound at ~734 rps, so the
// serialization ranking is taken at n=100.
export function itemCount(raw: string | null | undefined): number {
  if (raw === undefined || raw === null || raw === "") return DEFAULT_ITEMS;
  const n = Number.parseInt(raw, 10);
  if (Number.isNaN(n) || n < 0) return DEFAULT_ITEMS;
  return Math.min(n, MAX_ITEMS);
}

export function buildItems(n: number): JsonItem[] {
  const items = new Array<JsonItem>(n);
  for (let i = 0; i < n; i++) items[i] = canonicalItem(i);
  return items;
}
