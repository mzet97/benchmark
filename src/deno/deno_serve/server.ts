import { buildItems, itemCount } from "./canonical.ts";
/**
 * Benchmark API - Deno.serve (Native)
 * High-performance REST API benchmark implementation using Deno.serve()
 */

import { Client } from "https://deno.land/x/postgres@v0.19.3/mod.ts";
import { connect, parseURL, type Redis } from "https://deno.land/x/redis@v0.32.1/mod.ts";

// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

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
      'SELECT id, email, first_name AS "firstName", last_name AS "lastName", '
      + 'age, created_at AS "createdAt" FROM users WHERE id = $1',
      [userId]
    );
    return result.rows[0] || null;
  }

  async getComplexQuery(days: number) {
    if (!this.client) throw new Error("Database not initialized");
    const result = await this.client.queryObject(`
      -- Normative SQL, see contracts/rest/canonical-payloads.md. The previous
      -- query interpolated \`days\` straight into the SQL, joined order_items
      -- for no selected column, and ordered without a tiebreak.
      SELECT
        u.id AS "userId",
        u.first_name || ' ' || u.last_name AS "userName",
        COUNT(o.id) AS "totalOrders",
        COALESCE(SUM(o.total_amount), 0) AS "totalValue",
        COALESCE(AVG(o.total_amount), 0) AS "averageOrderValue"
      FROM users u
      INNER JOIN orders o ON u.id = o.user_id
        WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY "totalOrders" DESC, u.id
      LIMIT 100
    `, [days]);
    return result.rows;
  }
}

// ==================== Cache Service ====================
class CacheService {
  private redis: Redis | null = null;

  async init() {
    // Use the redis library's own parseURL rather than `new URL(...)` +
    // manual field copying. parseURL percent-decodes the userinfo, so a
    // password like Admin%40123 in REDIS_URL is sent to Redis as Admin@123.
    // The previous `new URL()` path forwarded the still-encoded password
    // and Redis auth failed with "WRONGPASS", crashing the worker.
    const parsed = parseURL(REDIS_URL);
    this.redis = await connect({
      hostname: parsed.hostname,
      port: typeof parsed.port === "string"
        ? parseInt(parsed.port, 10)
        : (parsed.port ?? 6379),
      password: parsed.password,
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
        periodDays: days,
        totalUsers: results.length,
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
        return new Response(JSON.stringify({ key, value: cached, cached: true, ttl: CACHE_TTL_SECONDS, timestamp: new Date().toISOString() }), { headers: jsonHeaders });
      }
      const value = `Cached value for ${key} at ${new Date().toISOString()}`;
      await cache.set(key, value, CACHE_TTL_SECONDS);
      return new Response(JSON.stringify({ key, value, cached: false, ttl: CACHE_TTL_SECONDS, timestamp: new Date().toISOString() }), { headers: jsonHeaders });
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
const PORT = parseInt(Deno.env.get("PORT") || "8080");
console.log(`🚀 Deno.serve server starting on port ${PORT}`);

// reusePort sets SO_REUSEPORT, which is what lets the BENCH_CPUS workers
// forked by index.ts share this socket instead of fighting over it.
Deno.serve({ port: PORT, reusePort: true }, handleRequest);
