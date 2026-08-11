// Response schemas are not documentation here: fast-json-stringify emits only
// the properties declared below, so a field missing from the schema is a field
// missing from the wire. They must track
// contracts/rest/canonical-payloads.md exactly.
//
// /db/simple used to answer {user: {...}, timestamp} with snake_case fields,
// and /db/complex answered {orders, count, days, timestamp} -- neither matched
// the contract envelope.
//
// `required` is not decoration either, and it is the reason this file was
// revisited. The drop is symmetric and the comment above only covered one
// direction: a property declared in the schema but *absent from the row object*
// is silently omitted too. When the SQL and the schema disagree about a field
// name, fast-json-stringify emits `{}` for every row -- a well-formed 200 with
// an empty payload, which no key-set parity check and no non_2xx counter
// notices.
//
// That is not hypothetical. scripts/audit-response-bytes.py flagged
// /db/complex here at 1,661 B/response across three runs and 536 B in a fourth,
// against a 10,895 B median for the same endpoint -- the two values correspond
// to one surviving field per row and to none at all, i.e. two different stale
// images whose SQL predated the camelCase aliases this schema expects. The
// current SQL in services/DatabaseService.js does match, so a rebuild fixes the
// payload; `required` is what makes the *next* divergence fail loudly instead of
// quietly, per invariante 8 in docs/ACTION_PLAN.md. fast-json-stringify throws
// on a missing required property, and server.js's error handler turns that into
// a 500 the load generator counts.
const userSchema = {
  type: 'object',
  required: ['id', 'email', 'firstName', 'lastName', 'age', 'createdAt'],
  properties: {
    id: { type: 'number' },
    email: { type: 'string' },
    firstName: { type: 'string' },
    lastName: { type: 'string' },
    // Nullable by contract, but the key is always present: the SELECT lists it,
    // so `required` is satisfied by an explicit null.
    age: { type: ['number', 'null'] },
    createdAt: { type: 'string' }
  }
};

const userStatsSchema = {
  type: 'object',
  required: ['userId', 'userName', 'totalOrders', 'totalValue',
             'averageOrderValue'],
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
