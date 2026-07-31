import { buildItems, itemCount, DEFAULT_ITEMS, MAX_ITEMS } from '../models/JsonItem.js';

export default async function jsonRoutes(fastify, options) {
  // JSON response endpoint.
  //
  // The response schema must declare every field of the canonical payload:
  // fastify's fast-json-stringify serializes ONLY declared properties, so a
  // stale schema silently strips fields and the payload diverges from
  // contracts/rest/canonical-payloads.md no matter what the handler returns.
  fastify.get('/json', {
    schema: {
      tags: ['json'],
      summary: 'JSON response',
      description: 'Returns n canonical JSON objects (default 1000)',
      querystring: {
        type: 'object',
        properties: {
          n: { type: 'integer', minimum: 0, maximum: MAX_ITEMS, default: DEFAULT_ITEMS }
        }
      },
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
                  uuid: { type: 'string' },
                  name: { type: 'string' },
                  email: { type: 'string' },
                  createdAt: { type: 'string' },
                  isActive: { type: 'boolean' }
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
    const n = itemCount(request.query.n);

    // The envelope timestamp is the only clock-dependent field and is
    // excluded from the parity hash.
    return {
      items: buildItems(n),
      count: n,
      timestamp: new Date().toISOString()
    };
  });
}
