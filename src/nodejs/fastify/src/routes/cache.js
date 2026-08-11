// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

export default async function cacheRoutes(fastify, options) {
  // Cache operations
  fastify.get('/cache', {
    schema: {
      tags: ['cache'],
      summary: 'Cache operations',
      description: 'Get or set cache value',
      querystring: {
        type: 'object',
        properties: {
          key: { type: 'string', default: 'test' }
        }
      },
      response: {
        200: {
          type: 'object',
          // See routes/database.js: without `required`, a property declared here
          // but absent from the returned object is dropped silently, inside a
          // 200. With it, fast-json-stringify throws and server.js answers 500.
          required: ['key', 'value', 'cached', 'ttl', 'timestamp'],
          properties: {
            key: { type: 'string' },
            value: { type: 'string' },
            cached: { type: 'boolean' },
            ttl: { type: 'number' },
            timestamp: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const key = request.query.key || 'test';

    // Try to get from cache first
    const cachedValue = await fastify.cacheService.get(key);

    if (cachedValue) {
      return {
        key,
        value: cachedValue,
        cached: true,
        ttl: CACHE_TTL_SECONDS,
        timestamp: new Date().toISOString()
      };
    }

    // No `await new Promise(resolve => setTimeout(resolve, 50))` here. It was
    // hidden work on the measured path (invariante 1 in docs/ACTION_PLAN.md).
    // On the kotlin/spring sibling that carried the same 50 ms sleep the cache
    // read never hit, so every request paid it and /cache measured 1,962 rps
    // against the 100-connections / 50 ms ceiling of 2,000 -- the number
    // described the delay, not Redis. And even where the read does hit, the
    // measurement window (30 s warmup + 5 x 60 s = 330 s) outlives the 300 s
    // TTL, so the key expires mid-sequence and one repetition eats the stall.
    const newValue = `Cached value for ${key} at ${new Date().toISOString()}`;

    // Store in cache
    await fastify.cacheService.set(key, newValue, CACHE_TTL_SECONDS);

    return {
      key,
      value: newValue,
      cached: false,
      ttl: CACHE_TTL_SECONDS,
      timestamp: new Date().toISOString()
    };
  });
}
