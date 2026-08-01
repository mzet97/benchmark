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

    // Simulate work
    await new Promise(resolve => setTimeout(resolve, 50));
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
