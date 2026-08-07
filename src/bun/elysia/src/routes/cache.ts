import { Elysia } from 'elysia';
import { cacheService } from '../services/cache';
import { CacheResponse } from '../types';

// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

export const cacheRoutes = new Elysia()
  .get('/cache', async ({ request }) => {
    const url = new URL(request.url);
    const key = url.searchParams.get('key');

    if (!key) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'key parameter is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Try to get from cache
    const cached = await cacheService.get(key);

    if (cached) {
      const response: CacheResponse = {
        key,
        value: cached,
        cached: true,
        ttl: CACHE_TTL_SECONDS,
        timestamp: new Date().toISOString(),
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Generate new value
    const value = `cached_data_${key}_${Date.now()}`;

    // Store in cache
    await cacheService.set(key, value, CACHE_TTL_SECONDS);

    const response: CacheResponse = {
      key,
      value,
      cached: false,
      ttl: CACHE_TTL_SECONDS,
      timestamp: new Date().toISOString(),
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  });
