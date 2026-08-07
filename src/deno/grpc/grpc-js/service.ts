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


interface GrpcCall {
  request: Record<string, unknown>;
}

interface GrpcCallback {
  (err: unknown, response?: Record<string, unknown>): void;
}

/**
 * Scenario 1: Health check
 */
export async function Health(call: GrpcCall, callback: GrpcCallback): Promise<void> {
  try {
    const [dbStatus, cacheStatus] = await Promise.all([
      db.checkHealth(),
      cache.checkHealth(),
    ]);

    callback(null, {
      status: "ok",
      version: VERSION,
      timestamp: new Date().toISOString(),
      database: dbStatus,
      cache: cacheStatus,
    });
  } catch (err) {
    callback(err);
  }
}

/**
 * Scenario 2: JSON serialization (1000 items)
 */
export async function GetJsonItems(call: GrpcCall, callback: GrpcCallback): Promise<void> {
  try {
    const count = itemCount(call.request.limit);
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

    callback(null, {
      items,
      count: items.length,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    callback(err);
  }
}

/**
 * Scenario 3: Simple database query (single row)
 */
export async function GetUser(call: GrpcCall, callback: GrpcCallback): Promise<void> {
  try {
    const user = (await db.getUser(call.request.id as number)) as Record<string, unknown> | null;
    if (!user) {
      return callback({
        code: 5, // NOT_FOUND
        message: `User with id ${call.request.id} not found`,
      });
    }

    callback(null, {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      age: user.age,
      created_at: user.created_at instanceof Date
        ? (user.created_at as Date).toISOString()
        : String(user.created_at),
    });
  } catch (err) {
    callback(err);
  }
}

/**
 * Scenario 4: Complex database query (JOIN + aggregation)
 */
export async function GetComplexOrders(call: GrpcCall, callback: GrpcCallback): Promise<void> {
  try {
    const days = (call.request.days as number) || 30;
    const data = await db.getComplexOrders(days);

    callback(null, {
      period_days: days,
      total_users: data.length,
      data,
    });
  } catch (err) {
    callback(err);
  }
}

/**
 * Scenario 5: Cache hit/miss
 */
export async function GetCacheValue(call: GrpcCall, callback: GrpcCallback): Promise<void> {
  try {
    const key = call.request.key as string;
    const result = await cache.getValue(key);

    callback(null, {
      key,
      value: result.value,
      cached: result.cached,
      ttl: result.ttl,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    callback(err);
  }
}
