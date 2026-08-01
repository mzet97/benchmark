import { Hono } from 'hono';
import { cacheService } from '../services/cache.ts';
import type { CacheResponse } from '../types.ts';

// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

export const cacheRoutes = new Hono();

// Cache endpoint
cacheRoutes.get('/cache', async (c) => {
  try {
    const key = c.req.query('key') || 'test';
    const cached = await cacheService.get(key);

    if (cached !== null) {
      const response: CacheResponse = {
        key,
        value: cached,
        cached: true,
        ttl: CACHE_TTL_SECONDS,
      };

      return c.json(response);
    }

    const value = `cached_data_${key}_${Date.now()}`;
    await cacheService.set(key, value, CACHE_TTL_SECONDS);

    const response: CacheResponse = {
      key,
      value,
      cached: false,
      ttl: CACHE_TTL_SECONDS,
    };

    return c.json(response);
  } catch (error) {
    return c.json({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }, 500);
  }
});
