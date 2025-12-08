import { createUser } from '../models/User.js';
import { createComplexOrderResult } from '../models/ComplexOrderResult.js';

export default async function databaseRoutes(fastify, options) {
  // Simple database query
  fastify.get('/db/simple', {
    schema: {
      tags: ['database'],
      summary: 'Simple database query',
      description: 'Get user by ID',
      querystring: {
        type: 'object',
        properties: {
          id: { type: 'integer', minimum: 1, default: 1 }
        }
      },
      response: {
        200: {
          type: 'object',
          properties: {
            user: {
              type: 'object',
              properties: {
                id: { type: 'number' },
                email: { type: 'string' },
                first_name: { type: 'string' },
                last_name: { type: 'string' },
                age: { type: 'number' },
                created_at: { type: 'string' }
              }
            },
            timestamp: { type: 'string' }
          }
        },
        404: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            id: { type: 'number' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const id = parseInt(request.query.id) || 1;

    const row = await fastify.dbService.findUserById(id);

    if (!row) {
      reply.code(404);
      return {
        error: 'User not found',
        id
      };
    }

    const user = createUser(row);

    return {
      user,
      timestamp: new Date().toISOString()
    };
  });

  // Complex database query
  fastify.get('/db/complex', {
    schema: {
      tags: ['database'],
      summary: 'Complex database query',
      description: 'Get aggregated order statistics',
      querystring: {
        type: 'object',
        properties: {
          days: { type: 'integer', minimum: 1, maximum: 365, default: 30 }
        }
      },
      response: {
        200: {
          type: 'object',
          properties: {
            orders: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  user_id: { type: 'number' },
                  email: { type: 'string' },
                  order_count: { type: 'number' },
                  total_amount: { type: 'number' },
                  avg_amount: { type: 'number' },
                  days_since_first_order: { type: 'number' }
                }
              }
            },
            count: { type: 'number' },
            days: { type: 'number' },
            timestamp: { type: 'string' }
          }
        },
        500: {
          type: 'object',
          properties: {
            error: { type: 'string' }
          }
        }
      }
    }
  }, async (request, reply) => {
    const days = parseInt(request.query.days) || 30;

    const rows = await fastify.dbService.findComplexOrders(days);
    const orders = rows.map(createComplexOrderResult);

    return {
      orders,
      count: orders.length,
      days,
      timestamp: new Date().toISOString()
    };
  });
}
