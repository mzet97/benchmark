import { createJsonItem } from '../models/JsonItem.js';

export default async function jsonRoutes(fastify, options) {
  // JSON response endpoint
  fastify.get('/json', {
    schema: {
      tags: ['json'],
      summary: 'JSON response',
      description: 'Returns 1000 JSON objects',
      response: {
        200: {
          type: 'object',
          properties: {
            items: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  id: { type: 'number' },
                  name: { type: 'string' },
                  description: { type: 'string' },
                  timestamp: { type: 'string' },
                  random: { type: 'string' }
                }
              }
            },
            count: { type: 'number' },
            timestamp: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const items = [];
    for (let i = 0; i < 1000; i++) {
      items.push(createJsonItem(i));
    }

    return {
      items,
      count: items.length,
      timestamp: items[0].timestamp
    };
  });
}
