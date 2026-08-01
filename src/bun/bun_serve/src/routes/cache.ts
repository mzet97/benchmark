import { cacheService } from '../services/cache.ts';
import type { CacheResponse } from '../types.ts';

// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

export async function cacheHandler(request: Request): Promise<Response> {
  try {
    const url = new URL(request.url);
    const key = url.searchParams.get('key') || 'test';
    const cached = await cacheService.get(key);

    if (cached !== null) {
      const response: CacheResponse = {
        key,
        value: cached,
        cached: true,
        ttl: CACHE_TTL_SECONDS,
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }

    const value = `cached_data_${key}_${Date.now()}`;
    await cacheService.set(key, value, CACHE_TTL_SECONDS);

    const response: CacheResponse = {
      key,
      value,
      cached: false,
      ttl: CACHE_TTL_SECONDS,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }
}
