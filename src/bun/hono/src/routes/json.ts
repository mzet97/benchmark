import { Hono } from 'hono';
import type { JsonItem } from '../types.ts';

export const jsonRoutes = new Hono();

// JSON endpoint
jsonRoutes.get('/json', (c) => {
  const items: JsonItem[] = [];

  for (let i = 0; i < 1000; i++) {
    items.push({
      id: i + 1,
      name: `Item ${i + 1}`,
      value: `Value ${i + 1}`,
      timestamp: new Date().toISOString(),
    });
  }

  return c.json({
    items,
    count: items.length,
  });
});
