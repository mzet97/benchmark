/**
 * Benchmark API - Deno Hono
 * High-performance REST API benchmark implementation
 */

import { Hono } from "https://deno.land/x/hono@v4.3.0/mod.ts";
import { Client } from "postgres";
import { Redis } from "redis";
import { buildItems, itemCount } from "./canonical.ts";

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

// ==================== Hono App ====================
const app = new Hono();

// Health check
app.get("/health", async (c) => {
  const dbOk = await db.healthCheck();
  const cacheOk = await cache.ping();
  const healthy = dbOk && cacheOk;
  return c.json({
    status: healthy ? "healthy" : "unhealthy",
    version: "1.0.0",
    timestamp: new Date().toISOString(),
    database: dbOk ? "connected" : "disconnected",
    cache: cacheOk ? "connected" : "disconnected",
  }, healthy ? 200 : 503);
});

// Kubernetes healthz
app.get("/healthz", (c) => c.json({ status: "ok" }));

// Root
app.get("/", (c) => c.json({
  name: "Benchmark API - Deno Hono",
  version: "1.0.0",
  runtime: "Deno",
  framework: "Hono",
  database: "PostgreSQL",
  cache: "Redis",
  status: "running",
}));

// JSON serialization
app.get("/json", (c) => {
  const n = itemCount(c.req.query("n"));

  // The envelope timestamp is the only clock-dependent field and is excluded
  // from the parity hash.
  return c.json({
    items: buildItems(n),
    count: n,
    timestamp: new Date().toISOString(),
  });
});

// Simple DB query
app.get("/db/simple", async (c) => {
  const idParam = c.req.query("id");
  if (!idParam) return c.json({ error: "Invalid id parameter" }, 400);
  const userId = parseInt(idParam);
  if (isNaN(userId) || userId <= 0) return c.json({ error: "Invalid id parameter" }, 400);
  const user = await db.getUser(userId);
  if (!user) return c.json({ error: `User with id ${userId} not found` }, 404);
  return c.json(user);
});

// Complex DB query
app.get("/db/complex", async (c) => {
  const days = parseInt(c.req.query("days") || "30");
  if (isNaN(days) || days <= 0 || days > 365) return c.json({ error: "Days must be between 1 and 365" }, 400);
  const results = await db.getComplexQuery(days);
  return c.json({
    period_days: days,
    total_users: results.length,
    data: results,
    timestamp: new Date().toISOString(),
  });
});

// Cache
app.get("/cache", async (c) => {
  const key = c.req.query("key");
  if (!key) return c.json({ error: "Key parameter is required" }, 400);
  const cached = await cache.get(key);
  if (cached) {
    return c.json({ key, value: cached, cached: true, timestamp: new Date().toISOString() });
  }
  const value = `Cached value for ${key} at ${new Date().toISOString()}`;
  await cache.set(key, value, 300);
  return c.json({ key, value, cached: false, timestamp: new Date().toISOString() });
});

// Error handler
app.onError((err, c) => {
  console.error("Unhandled error:", err);
  return c.json({ error: "Internal Server Error", message: String(err) }, 500);
});

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
console.log(`🚀 Deno Hono server starting on port ${PORT}`);

Deno.serve({ port: PORT }, app.fetch);
