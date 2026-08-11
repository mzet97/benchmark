import { buildItems, itemCount, DEFAULT_ITEMS, MAX_ITEMS } from '../models/JsonItem.js';

export default async function jsonRoutes(fastify, options) {
  // JSON response endpoint.
  //
  // The response schema must declare every field of the canonical payload:
  // fastify's fast-json-stringify serializes ONLY declared properties, so a
  // stale schema silently strips fields and the payload diverges from
  // contracts/rest/canonical-payloads.md no matter what the handler returns.
  //
  // `required` closes the other half of that hole: a property declared here but
  // absent from the object the handler returns is *also* dropped silently. With
  // `required`, fast-json-stringify throws and server.js's error handler answers
  // 500, so the load generator's non_2xx counter registers it (invariante 8 in
  // docs/ACTION_PLAN.md). This is not a theoretical concern -- /db/complex on
  // this same service shipped 1,661 B/response against a 10,895 B median for
  // three measured runs because exactly one field name matched; see
  // routes/database.js.
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
          required: ['items', 'count', 'timestamp'],
          properties: {
            items: {
              type: 'array',
              items: {
                type: 'object',
                required: ['id', 'uuid', 'name', 'email', 'createdAt',
                           'isActive'],
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
