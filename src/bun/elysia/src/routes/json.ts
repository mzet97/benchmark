import { Elysia } from 'elysia';
import { JsonItem } from '../types';

function generateJsonItems(): JsonItem[] {
  const items: JsonItem[] = [];
  const now = new Date().toISOString();

  for (let i = 0; i < 1000; i++) {
    items.push({
      id: i + 1,
      name: `Item ${i + 1}`,
      value: `Value ${i + 1}`,
      timestamp: now
    });
  }

  return items;
}

export const jsonRoutes = new Elysia()
  .get('/json', () => {
    return generateJsonItems();
  });
