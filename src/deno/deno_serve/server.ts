/**
 * Benchmark API - Deno.serve (Native)
 * High-performance REST API benchmark implementation using Deno.serve()
 */

import { Client } from "https://deno.land/x/postgres@v0.19.3/mod.ts";
import { Redis } from "https://deno.land/x/redis@v0.32.1/mod.ts";

const DATABASE_URL = Deno.env.get("DATABASE_URL") || "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api";
const REDIS_URL = Deno.env.get("REDIS_URL") || "redis://:Admin@123@redis.home.arpa:30379";

// ==================== Database Service ====================
class DatabaseService {
  private client: Client | null = null;

  async init() {
    this.client = new Client(DATABASE_URL);
    await this.client.connect();
    console.log("Database connected");
  }

  async close() {
    if (this.client) await this.client.end();
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
    if (this.redis) await this.redis.quit();
  }

  async ping(): Promise<boolean> {
    if (!this.redis) return false;
    try { await this.redis.ping(); return true; } catch { return false; }
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

// ==================== Initialize ====================
const db = new DatabaseService();
const cache = new CacheService();
await db.init();
await cache.init();

// ==================== Router ====================
const jsonHeaders = { "Content-Type": "application/json" };

const handleRequest = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const path = url.pathname;

  try {
    // Health check
    if (path === "/health") {
      const dbOk = await db.healthCheck();
      const cacheOk = await cache.ping();
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
        name: "Benchmark API - Deno.serve",
        version: "1.0.0",
        runtime: "Deno",
        framework: "Deno.serve",
        database: "PostgreSQL",
        cache: "Redis",
        status: "running",
      }), { headers: jsonHeaders });
    }

    // JSON serialization
    if (path === "/json") {
      const timestamp = new Date().toISOString();
      const items = Array.from({ length: 1000 }, (_, i) => ({
        id: i + 1,
        uuid: crypto.randomUUID(),
        name: `Item ${i + 1}`,
        description: `This is item number ${i + 1}`,
        timestamp,
        random: `data-${crypto.randomUUID()}`,
      }));
      return new Response(JSON.stringify({ items, count: 1000, timestamp }), { headers: jsonHeaders });
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
      const user = await db.getUser(userId);
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
      const results = await db.getComplexQuery(days);
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
      const cached = await cache.get(key);
      if (cached) {
        return new Response(JSON.stringify({ key, value: cached, cached: true, timestamp: new Date().toISOString() }), { headers: jsonHeaders });
      }
      const value = `Cached value for ${key} at ${new Date().toISOString()}`;
      await cache.set(key, value, 300);
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
  await db.close();
  await cache.close();
  Deno.exit(0);
};
Deno.addSignalListener("SIGINT", shutdown);
Deno.addSignalListener("SIGTERM", shutdown);

// ==================== Start Server ====================
const PORT = parseInt(Deno.env.get("PORT") || "3000");
console.log(`🚀 Deno.serve server starting on port ${PORT}`);

Deno.serve({ port: PORT }, handleRequest);
