import { Hono } from "hono";
import { graphqlServer } from "@hono/graphql-server";
import { buildSchema } from "graphql";
import { typeDefs } from "./typeDefs.ts";
import { checkDatabase, getUser, getComplexOrders } from "./db.ts";
import { checkCache, getCache, setCache } from "./cache.ts";

const PORT = parseInt(Deno.env.get("PORT") || "3000");

const schema = buildSchema(typeDefs);

const rootValue = {
  health: async () => {
    const dbOk = await checkDatabase();
    const cacheOk = await checkCache();
    return {
      status: dbOk && cacheOk ? "healthy" : "unhealthy",
      version: "1.0.0",
      timestamp: new Date().toISOString(),
      database: dbOk ? "connected" : "disconnected",
      cache: cacheOk ? "connected" : "disconnected",
    };
  },

  jsonItems: async ({ limit = 1000 }: { limit: number }) => {
    const timestamp = new Date().toISOString();
    const items = [];
    for (let i = 0; i < limit; i++) {
      items.push({
        id: i + 1,
        uuid: crypto.randomUUID(),
        name: `Item ${i + 1}`,
        email: `user${i + 1}@example.com`,
        createdAt: timestamp,
        isActive: i % 2 === 0,
      });
    }
    return { items, count: limit, timestamp };
  },

  user: async ({ id }: { id: number }) => {
    return await getUser(id);
  },

  complexOrders: async ({ days = 30 }: { days: number }) => {
    const data = await getComplexOrders(days);
    return {
      periodDays: days,
      totalUsers: data.length,
      data,
    };
  },

  cache: async ({ key }: { key: string }) => {
    const cached = await getCache(key);
    if (cached) {
      return { key, value: cached, cached: true, ttl: 300 };
    }
    const value = `Cache value for ${key} at ${new Date().toISOString()}`;
    await setCache(key, value, 300);
    return { key, value, cached: false, ttl: 300 };
  },
};

const app = new Hono();

// Health check endpoint for k8s probes
app.get("/health", (c) => {
  return c.json({ status: "ok", version: "1.0.0" });
});

// GraphQL endpoint
app.post("/graphql", graphqlServer({ schema, rootValue }));

// 404 for all other routes
app.all("*", (c) => {
  return c.json({ error: "Not Found" }, 404);
});

Deno.serve({ port: PORT }, app.fetch);

console.log(`Deno Hono GraphQL Server running on port ${PORT}`);
