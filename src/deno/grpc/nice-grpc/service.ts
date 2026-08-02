import * as db from "./db.ts";
import * as cache from "./cache.ts";
import {
  CANONICAL_CREATED_AT,
  canonicalEmail,
  canonicalIsActive,
  canonicalName,
  canonicalUuid,
  itemCount,
} from './canonical.ts';

const VERSION = Deno.env.get("APP_VERSION") || "1.0.0";

/**
 * BenchmarkService implementation for nice-grpc on Deno.
 * nice-grpc service methods receive (request, context) and return the response directly.
 */
export default {
  // Scenario 1: Health check
  async health(request: Record<string, unknown>, _context: unknown) {
    try {
      const [dbStatus, cacheStatus] = await Promise.all([
        db.healthCheck(),
        cache.healthCheck(),
      ]);

      return {
        status: "ok",
        version: VERSION,
        timestamp: new Date().toISOString(),
        database: dbStatus,
        cache: cacheStatus,
      };
    } catch (err) {
      console.error("Health check error:", err);
      return {
        status: "degraded",
        version: VERSION,
        timestamp: new Date().toISOString(),
        database: "unknown",
        cache: "unknown",
      };
    }
  },

  // Scenario 2: JSON serialization (1000 items)
  async getJsonItems(request: Record<string, unknown>, _context: unknown) {
    const limit = (request.limit as number) > 0 ? (request.limit as number) : 1000;
    const items = [];

    for (let i = 0; i < count; i++) {
      items.push({
        id: i,
        uuid: canonicalUuid(i),
        name: canonicalName(i),
        email: canonicalEmail(i),
        created_at: CANONICAL_CREATED_AT,
        is_active: canonicalIsActive(i),
      });
    }

    return {
      items,
      count: items.length,
      timestamp: new Date().toISOString(),
    };
  },

  // Scenario 3: Simple database query
  async getUser(request: Record<string, unknown>, _context: unknown) {
    const id = request.id as number;
    const result = await db.query(
      "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
      [id]
    );

    if (result.rows.length === 0) {
      const err = new Error(`User with id ${id} not found`) as Error & { code: number };
      err.code = 5; // NOT_FOUND
      throw err;
    }

    const user = result.rows[0] as Record<string, unknown>;
    return {
      id: user.id as number,
      email: (user.email as string) || "",
      first_name: (user.first_name as string) || "",
      last_name: (user.last_name as string) || "",
      age: (user.age as number) || 0,
      created_at: user.created_at instanceof Date
        ? (user.created_at as Date).toISOString()
        : String(user.created_at || ""),
    };
  },

  // Scenario 4: Complex database query (JOIN + aggregation)
  async getComplexOrders(request: Record<string, unknown>, _context: unknown) {
    const days = (request.days as number) > 0 ? (request.days as number) : 30;

    const result = await db.query(
      `SELECT
        u.id as user_id,
        u.first_name || ' ' || u.last_name as user_name,
        COUNT(o.id) as total_orders,
        COALESCE(SUM(o.total_amount), 0) as total_value,
        COALESCE(AVG(o.total_amount), 0) as average_order_value
      FROM users u
      LEFT JOIN orders o ON u.id = o.user_id
        AND o.created_at >= NOW() - INTERVAL '${days} days'
      GROUP BY u.id, u.first_name, u.last_name
      HAVING COUNT(o.id) > 0
      ORDER BY total_value DESC
      LIMIT 100`
    );

    const data = result.rows.map((row: Record<string, unknown>) => ({
      user_id: row.user_id as number,
      user_name: (row.user_name as string) || "",
      total_orders: parseInt(row.total_orders as string) || 0,
      total_value: parseFloat(row.total_value as string) || 0,
      average_order_value: parseFloat(row.average_order_value as string) || 0,
    }));

    return {
      period_days: days,
      total_users: data.length,
      data,
    };
  },

  // Scenario 5: Cache hit/miss
  async getCacheValue(request: Record<string, unknown>, _context: unknown) {
    const key = request.key as string;
    const result = await cache.get(key);

    if (result.hit) {
      return {
        key,
        value: result.value,
        cached: true,
        ttl: 300,
        timestamp: new Date().toISOString(),
      };
    }

    // Cache miss - generate a value and store it
    const value = `value-${Date.now()}`;
    await cache.set(key, value, 300);

    return {
      key,
      value,
      cached: false,
      ttl: 300,
      timestamp: new Date().toISOString(),
    };
  },
};
