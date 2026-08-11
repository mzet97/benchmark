'use strict';

import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import express from 'express';
import http from 'http';
import { typeDefs } from './typeDefs.js';
import { resolvers } from './resolvers.js';

const PORT = parseInt(process.env.PORT || '8080', 10);

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
