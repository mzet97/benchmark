import { v4 as uuidv4 } from 'uuid';

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
            source: { type: 'string' },
            timestamp: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const key = request.query.key || 'test';
    const newValue = `cached-value-${uuidv4()}`;

    const result = await fastify.cacheService.getOrSet(key, newValue, 300);

    return {
      key,
      value: result.value,
      source: result.source,
      timestamp: new Date().toISOString()
    };
  });
}
