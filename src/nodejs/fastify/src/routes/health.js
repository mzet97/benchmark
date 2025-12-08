import { createHealthResponse } from '../models/HealthResponse.js';

export default async function healthRoutes(fastify, options) {
  // Health check endpoint
  fastify.get('/health', {
    schema: {
      tags: ['health'],
      summary: 'Health check',
      description: 'Check database and cache connectivity',
      response: {
        200: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            database: { type: 'string' },
            cache: { type: 'string' },
            timestamp: { type: 'string' }
          }
        },
        503: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            database: { type: 'string' },
            cache: { type: 'string' },
            timestamp: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const dbHealthy = await fastify.dbService.healthCheck();
    const cacheHealthy = await fastify.cacheService.healthCheck();

    const response = createHealthResponse(dbHealthy, cacheHealthy);

    if (dbHealthy && cacheHealthy) {
      reply.code(200);
    } else {
      reply.code(503);
    }

    return response;
  });
}
