'use strict';

const { ApolloServer } = require('@apollo/server');
const { expressMiddleware } = require('@apollo/server/express4');
const express = require('express');
const http = require('http');
const { typeDefs } = require('./typeDefs');
const { resolvers } = require('./resolvers');

const PORT = parseInt(process.env.PORT || '3000', 10);

async function start() {
  const app = express();
  const httpServer = http.createServer(app);

  app.use(express.json());

  const server = new ApolloServer({
    typeDefs,
    resolvers,
    introspection: false,
    includeStacktraceInErrorResponses: false,
  });

  await server.start();

  app.post('/graphql', expressMiddleware(server));

  app.get('/health', async (_req, res) => {
    res.json({ status: 'ok' });
  });

  await new Promise((resolve) => httpServer.listen({ port: PORT, host: '0.0.0.0' }, resolve));
  console.log(`Apollo Server GraphQL running on port ${PORT}`);
}

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
