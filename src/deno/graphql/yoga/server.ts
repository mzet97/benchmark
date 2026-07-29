import { createYoga, createSchema } from "graphql-yoga";
import { typeDefs } from "./schema.ts";
import { resolvers } from "./resolvers.ts";

const yoga = createYoga({
  schema: createSchema({ typeDefs, resolvers }),
  graphqlEndpoint: "/graphql",
  landingPage: false,
  graphiql: false,
  logging: false,
});

const PORT = parseInt(Deno.env.get("PORT") || "3000");

Deno.serve({ port: PORT }, async (req: Request) => {
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
});

console.log(`Deno GraphQL Yoga server running on port ${PORT}`);
