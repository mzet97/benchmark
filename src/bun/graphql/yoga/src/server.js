import { createYoga, createSchema } from "graphql-yoga";
import { typeDefs } from "./schema.js";
import { resolvers } from "./resolvers.js";

const yoga = createYoga({
  schema: createSchema({ typeDefs, resolvers }),
  graphqlEndpoint: "/graphql",
  landingPage: false,
  graphiql: false,
  logging: false,
});

const PORT = parseInt(process.env.PORT || '8080');

const server = Bun.serve({
  // Several worker processes bind the same port; the kernel balances
  // accepted connections across them. See src/index.js.
  reusePort: true,
  port: PORT,
  async fetch(req) {
    const url = new URL(req.url);

    // Health check endpoint for k8s probes
    if (url.pathname === "/health" && req.method === "GET") {
      return new Response(
        JSON.stringify({ status: "ok", version: "1.0.0" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // GraphQL endpoint
    if (url.pathname === "/graphql" && req.method === "POST") {
      return yoga.fetch(req);
    }

    return new Response(JSON.stringify({ error: "Not Found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  },
});

console.log(`Bun GraphQL Yoga server running on port ${PORT}`);
