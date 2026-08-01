import { buildItems, itemCount } from "./canonical.ts";
/**
 * Benchmark API - Deno Fresh
 * High-performance REST API benchmark implementation
 */

import { Client } from "postgres";
import { Redis } from "redis";

const PORT = parseInt(Deno.env.get("PORT") || "3000");
const DATABASE_URL = Deno.env.get("DATABASE_URL") || (() => { throw new Error('DATABASE_URL is required'); })();
const REDIS_URL = Deno.env.get("REDIS_URL") || (() => { throw new Error('REDIS_URL is required'); })();

// ==================== Database Service ====================
class DatabaseService {
  private client: Client | null = null;

  async init() {
    this.client = new Client(DATABASE_URL);
    await this.client.connect();
    console.log("Database connected");
  }

  async close() {
    if (this.client) {
      await this.client.end();
    }
  }

  async healthCheck(): Promise<boolean> {
    if (!this.client) return false;
    try {
      await this.client.queryObject("SELECT 1");
      return true;
    } catch {
      return false;
    }
  }

  async getUser(userId: number) {
    if (!this.client) throw new Error("Database not initialized");
    const result = await this.client.queryObject(
      "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
      [userId]
    );
    return result.rows[0] || null;
  }

  async getComplexQuery(days: number) {
    if (!this.client) throw new Error("Database not initialized");
    const result = await this.client.queryObject(`
      SELECT
        u.id as user_id,
        CONCAT(u.first_name, ' ', u.last_name) as user_name,
        COUNT(DISTINCT o.id) as total_orders,
        COALESCE(SUM(o.total_amount), 0) as total_value,
        COALESCE(AVG(o.total_amount), 0) as average_order_value
      FROM users u
      LEFT JOIN orders o ON u.id = o.user_id
        AND o.created_at >= NOW() - INTERVAL '${days} days'
        AND o.status = 'completed'
      LEFT JOIN order_items oi ON o.id = oi.order_id
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY total_value DESC
      LIMIT 100
    `);
    return result.rows;
  }
}

// ==================== Cache Service ====================
class CacheService {
  private redis: Redis | null = null;

  async init() {
    const url = new URL(REDIS_URL);
    this.redis = new Redis({
      hostname: url.hostname,
      port: parseInt(url.port || "6379"),
      password: url.password || undefined,
    });
    await this.redis.ping();
    console.log("Redis connected");
  }

  async close() {
    if (this.redis) {
      await this.redis.quit();
    }
  }

  async ping(): Promise<boolean> {
    if (!this.redis) return false;
    try {
      await this.redis.ping();
      return true;
    } catch {
      return false;
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.redis) throw new Error("Redis not initialized");
    return await this.redis.get(key);
  }

  async set(key: string, value: string, ttl: number = 300) {
    if (!this.redis) throw new Error("Redis not initialized");
    await this.redis.setex(key, ttl, value);
  }
}

// ==================== Initialize Services ====================
const databaseService = new DatabaseService();
const cacheService = new CacheService();

await databaseService.init();
await cacheService.init();

// ==================== Route Handlers ====================
const jsonHeaders = { "Content-Type": "application/json" };

const handleRequest = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const path = url.pathname;

  try {
    // Health check
    if (path === "/health") {
      const dbOk = await databaseService.healthCheck();
      const cacheOk = await cacheService.ping();
      const healthy = dbOk && cacheOk;
      return new Response(JSON.stringify({
        status: healthy ? "healthy" : "unhealthy",
        version: "1.0.0",
        timestamp: new Date().toISOString(),
        database: dbOk ? "connected" : "disconnected",
        cache: cacheOk ? "connected" : "disconnected",
      }), { status: healthy ? 200 : 503, headers: jsonHeaders });
    }

    // Kubernetes healthz
    if (path === "/healthz") {
      return new Response(JSON.stringify({ status: "ok" }), { headers: jsonHeaders });
    }

    // Root
    if (path === "/") {
      return new Response(JSON.stringify({
        name: "Benchmark API - Deno Fresh",
        version: "1.0.0",
        runtime: "Deno",
        framework: "Fresh",
        database: "PostgreSQL",
        cache: "Redis",
        status: "running",
      }), { headers: jsonHeaders });
    }

    // JSON serialization
    if (path === "/json") {
      const n = itemCount(url.searchParams.get("n"));
      // The envelope timestamp is the only clock-dependent field and is
      // excluded from the parity hash.
      return new Response(
        JSON.stringify({
          items: buildItems(n),
          count: n,
          timestamp: new Date().toISOString(),
        }),
        { headers: jsonHeaders },
      );
    }

    // Simple DB query
    if (path === "/db/simple") {
      const idParam = url.searchParams.get("id");
      if (!idParam) {
        return new Response(JSON.stringify({ error: "Invalid id parameter" }), { status: 400, headers: jsonHeaders });
      }
      const userId = parseInt(idParam);
      if (isNaN(userId) || userId <= 0) {
        return new Response(JSON.stringify({ error: "Invalid id parameter" }), { status: 400, headers: jsonHeaders });
      }
      const user = await databaseService.getUser(userId);
      if (!user) {
        return new Response(JSON.stringify({ error: `User with id ${userId} not found` }), { status: 404, headers: jsonHeaders });
      }
      return new Response(JSON.stringify(user), { headers: jsonHeaders });
    }

    // Complex DB query
    if (path === "/db/complex") {
      const days = parseInt(url.searchParams.get("days") || "30");
      if (isNaN(days) || days <= 0 || days > 365) {
        return new Response(JSON.stringify({ error: "Days must be between 1 and 365" }), { status: 400, headers: jsonHeaders });
      }
      const results = await databaseService.getComplexQuery(days);
      return new Response(JSON.stringify({
        period_days: days,
        total_users: results.length,
        data: results,
        timestamp: new Date().toISOString(),
      }), { headers: jsonHeaders });
    }

    // Cache
    if (path === "/cache") {
      const key = url.searchParams.get("key");
      if (!key) {
        return new Response(JSON.stringify({ error: "Key parameter is required" }), { status: 400, headers: jsonHeaders });
      }
      const cached = await cacheService.get(key);
      if (cached) {
        return new Response(JSON.stringify({ key, value: cached, cached: true, timestamp: new Date().toISOString() }), { headers: jsonHeaders });
      }
      const value = `Cached value for ${key} at ${new Date().toISOString()}`;
      await cacheService.set(key, value, 300);
      return new Response(JSON.stringify({ key, value, cached: false, timestamp: new Date().toISOString() }), { headers: jsonHeaders });
    }

    return new Response(JSON.stringify({ error: "Not Found" }), { status: 404, headers: jsonHeaders });
  } catch (error) {
    console.error("Unhandled error:", error);
    return new Response(JSON.stringify({ error: "Internal Server Error", message: String(error) }), { status: 500, headers: jsonHeaders });
  }
};

// ==================== Graceful Shutdown ====================
const shutdown = async () => {
  console.log("Shutting down...");
  await databaseService.close();
  await cacheService.close();
  Deno.exit(0);
};

Deno.addSignalListener("SIGINT", shutdown);
Deno.addSignalListener("SIGTERM", shutdown);

// ==================== Start Server ====================
console.log(`🚀 Deno Fresh server starting on port ${PORT}`);
Deno.serve({ port: PORT }, handleRequest);
