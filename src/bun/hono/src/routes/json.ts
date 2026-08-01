import { Hono } from 'hono';
import { buildItems, itemCount } from '../canonical.ts';

export const jsonRoutes = new Hono();

jsonRoutes.get('/json', (c) => {
  const n = itemCount(c.req.query('n'));

  // The envelope timestamp is the only clock-dependent field and is excluded
  // from the parity hash.
  return c.json({
    items: buildItems(n),
    count: n,
    timestamp: new Date().toISOString(),
  });
});
