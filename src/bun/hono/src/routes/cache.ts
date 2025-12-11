import { Hono } from 'hono';
import { cacheService } from '../services/cache.ts';
import type { CacheResponse } from '../types.ts';

export const cacheRoutes = new Hono();

// Cache endpoint
cacheRoutes.get('/cache', async (c) => {
  try {
    const key = c.req.query('key') || 'test';
    const ttl = parseInt(process.env.CACHE_TTL || '300');

    const cached = await cacheService.get(key);

    if (cached !== null) {
      const response: CacheResponse = {
        key,
        value: cached,
        cached: true,
        ttl,
      };

      return c.json(response);
    }

    const value = `cached_data_${key}_${Date.now()}`;
    await cacheService.set(key, value, ttl);

    const response: CacheResponse = {
      key,
      value,
      cached: false,
      ttl,
    };

    return c.json(response);
  } catch (error) {
    return c.json({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }, 500);
  }
});
