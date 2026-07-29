import { checkDatabase, getUser, getComplexOrders } from "./db.ts";
import { checkCache, getCache, setCache } from "./cache.ts";

export const resolvers = {
  Query: {
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

    jsonItems: async (_parent: unknown, { limit = 1000 }: { limit: number }) => {
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

    user: async (_parent: unknown, { id }: { id: number }) => {
      return await getUser(id);
    },

    complexOrders: async (_parent: unknown, { days = 30 }: { days: number }) => {
      const data = await getComplexOrders(days);
      return {
        periodDays: days,
        totalUsers: data.length,
        data,
      };
    },

    cache: async (_parent: unknown, { key }: { key: string }) => {
      const cached = await getCache(key);
      if (cached) {
        return { key, value: cached, cached: true, ttl: 300 };
      }
      const value = `Cache value for ${key} at ${new Date().toISOString()}`;
      await setCache(key, value, 300);
      return { key, value, cached: false, ttl: 300 };
    },
  },
};
