import { cacheService } from '../services/cache.ts';
import type { CacheResponse } from '../types.ts';

export async function cacheHandler(request: Request): Promise<Response> {
  try {
    const url = new URL(request.url);
    const key = url.searchParams.get('key') || 'test';
    const ttl = parseInt(process.env.CACHE_TTL || '300');

    const cached = await cacheService.get(key);

    if (cached !== null) {
      const response: CacheResponse = {
        key,
        value: cached,
        cached: true,
        ttl,
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }

    const value = `cached_data_${key}_${DateTime.now().millisecondsSinceEpoch}`;
    await cacheService.set(key, value, ttl);

    const response: CacheResponse = {
      key,
      value,
      cached: false,
      ttl,
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
