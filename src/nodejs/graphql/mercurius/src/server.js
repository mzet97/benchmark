'use strict';

const fastify = require('fastify')({ logger: false });
const mercurius = require('mercurius');
const { typeDefs } = require('./schema');
const { resolvers } = require('./resolvers');

const PORT = parseInt(process.env.PORT || '8080', 10);

fastify.register(mercurius, {
  schema: typeDefs,
  resolvers,
  graphiql: false,
  ide: false,
  allowBatchedQueries: true,
  context: (req, reply) => ({
    req,
    reply
  })
});

fastify.post('/graphql', async (req, reply) => {
  return reply.graphql(req.body?.query || '', {
    variables: req.body?.variables,
    operationName: req.body?.operationName
  });
});

fastify.get('/health', async () => {
  return { status: 'ok' };
});

async function start() {
  try {
    await fastify.listen({ port: PORT, host: '0.0.0.0' });
    console.log(`Mercurius GraphQL server running on port ${PORT}`);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

start();
