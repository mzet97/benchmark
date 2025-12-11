import type { JsonItem } from '../types.ts';

export async function jsonHandler(request: Request): Promise<Response> {
  const items: JsonItem[] = [];

  for (let i = 0; i < 1000; i++) {
    items.push({
      id: i + 1,
      name: `Item ${i + 1}`,
      value: `Value ${i + 1}`,
      timestamp: new Date().toISOString(),
    });
  }

  return new Response(JSON.stringify({
    items,
    count: items.length,
  }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
    },
  });
}
