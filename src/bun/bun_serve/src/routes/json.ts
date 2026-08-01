import { buildItems, itemCount } from '../canonical.ts';

export async function jsonHandler(request: Request): Promise<Response> {
  const n = itemCount(new URL(request.url).searchParams.get('n'));

  // The envelope timestamp is the only clock-dependent field and is excluded
  // from the parity hash.
  return new Response(JSON.stringify({
    items: buildItems(n),
    count: n,
    timestamp: new Date().toISOString(),
  }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
    },
  });
}
