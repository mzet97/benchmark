'use strict';

import { createServer } from 'http';
import { createSchema, createYoga } from 'graphql-yoga';
import { typeDefs } from './typeDefs.js';
import { resolvers } from './resolvers.js';

const PORT = parseInt(process.env.PORT || '8080', 10);

const schema = createSchema({
  typeDefs,
  resolvers
});

const yoga = createYoga({
  schema,
  graphqlEndpoint: '/graphql',
  landingPage: false,
  graphiql: false
});

const server = createServer(yoga);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`GraphQL Yoga server running on port ${PORT}`);
});
