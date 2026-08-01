// Response schemas are not documentation here: fast-json-stringify emits only
// the properties declared below, so a field missing from the schema is a field
// missing from the wire. They must track
// contracts/rest/canonical-payloads.md exactly.
//
// /db/simple used to answer {user: {...}, timestamp} with snake_case fields,
// and /db/complex answered {orders, count, days, timestamp} -- neither matched
// the contract envelope.

const userSchema = {
  type: 'object',
  properties: {
    id: { type: 'number' },
    email: { type: 'string' },
    firstName: { type: 'string' },
    lastName: { type: 'string' },
    age: { type: ['number', 'null'] },
    createdAt: { type: 'string' }
  }
};

const userStatsSchema = {
  type: 'object',
  properties: {
    userId: { type: 'number' },
    userName: { type: 'string' },
    totalOrders: { type: 'number' },
    totalValue: { type: 'number' },
    averageOrderValue: { type: 'number' }
  }
};

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
        200: userSchema,
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

    // The normative SQL aliases its columns to the contract names, so the row
    // is already the response body.
    return row;
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
            periodDays: { type: 'number' },
            totalUsers: { type: 'number' },
            data: { type: 'array', items: userStatsSchema }
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

    const data = await fastify.dbService.findComplexOrders(days);

    return {
      periodDays: days,
      totalUsers: data.length,
      data
    };
  });
}
