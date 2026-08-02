'use strict';

const { createServer } = require('http');
const { createSchema, createYoga } = require('graphql-yoga');
const { typeDefs } = require('./typeDefs');
const { resolvers } = require('./resolvers');

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
