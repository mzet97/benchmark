import { Controller, DefaultValuePipe, Get, ParseIntPipe, Query } from '@nestjs/common';

// Canonical /json payload. See contracts/rest/canonical-payloads.md.
//
// The previous implementation numbered items from 1 instead of 0, returned
// {id,name,value,timestamp} instead of the contract shape, stamped
// new Date() into every item, and omitted timestamp from the envelope. It was
// ranked first on /json while serializing a smaller, different object.
const DEFAULT_ITEMS = 1000;
const MAX_ITEMS = 10000;
const CANONICAL_CREATED_AT = '2026-01-01T00:00:00Z';

interface JsonItem {
  id: number;
  uuid: string;
  name: string;
  email: string;
  createdAt: string;
  isActive: boolean;
}

// Item content is a pure function of the index: no randomness and no
// wall-clock, so the payload is identical across languages.
function canonicalItem(i: number): JsonItem {
  return {
    id: i,
    uuid: `00000000-0000-0000-0000-${String(i).padStart(12, '0')}`,
    name: `Item ${i}`,
    email: `item${i}@benchmark.local`,
    createdAt: CANONICAL_CREATED_AT,
    isActive: i % 2 === 0,
  };
}

@Controller('json')
export class JsonController {
  // ?n= is part of the contract: on a 1 GbE link n=1000 is network-bound at
  // ~734 rps, so the serialization ranking is taken at n=100.
  @Get()
  getJson(
    @Query('n', new DefaultValuePipe(DEFAULT_ITEMS), ParseIntPipe) n: number,
  ) {
    const count = Math.min(Math.max(n, 0), MAX_ITEMS);
    const items = new Array<JsonItem>(count);
    for (let i = 0; i < count; i++) {
      items[i] = canonicalItem(i);
    }

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    return {
      items,
      count,
      timestamp: new Date().toISOString(),
    };
  }
}
