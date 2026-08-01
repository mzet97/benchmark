import { Elysia } from 'elysia';
import { buildItems, itemCount } from '../canonical';

// The previous route returned a bare array with no envelope at all, while
// every other implementation returned {items,count,timestamp}. See
// contracts/rest/canonical-payloads.md.
export const jsonRoutes = new Elysia()
  .get('/json', ({ query }) => {
    const n = itemCount(query.n as string | undefined);

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    return {
      items: buildItems(n),
      count: n,
      timestamp: new Date().toISOString(),
    };
  });
