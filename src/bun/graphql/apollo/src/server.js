import { ApolloServer } from "@apollo/server";
import { typeDefs } from "./typeDefs.js";
import { resolvers } from "./resolvers.js";

const PORT = parseInt(process.env.PORT || "3000");

const server = new ApolloServer({
  typeDefs,
  resolvers,
  introspection: false,
});

await server.start();

const bunServer = Bun.serve({
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
      const body = await req.text();
      const headers = {};
      req.headers.forEach((value, key) => {
        headers[key] = value;
      });

      const httpGraphQLRequest = {
        method: "POST",
        headers,
        body: JSON.parse(body),
      };

      const response = await server.executeHTTPGraphQLRequest({
        httpGraphQLRequest,
        context: async () => ({}),
      });

      const responseHeaders = {};
      for (const [key, value] of response.headers) {
        responseHeaders[key] = value;
      }

      return new Response(
        response.body.kind === "complete"
          ? response.body.string
          : JSON.stringify(response.body),
        {
          status: response.status || 200,
          headers: {
            "Content-Type": "application/json",
            ...responseHeaders,
          },
        }
      );
    }

    return new Response(JSON.stringify({ error: "Not Found" }), {
      status: 404,
      headers: { "Content-Type": "application/json" },
    });
  },
});

console.log(`Bun Apollo Server running on port ${PORT}`);
