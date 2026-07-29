const { v4: uuidv4 } = require("crypto");
const db = require("./db");
const cache = require("./cache");

const VERSION = process.env.APP_VERSION || "1.0.0";

function generateUuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Scenario 1: Health check
 */
async function Health(call, callback) {
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
async function GetJsonItems(call, callback) {
  try {
    const limit = call.request.limit || 1000;
    const items = [];

    for (let i = 0; i < limit; i++) {
      items.push({
        id: i + 1,
        uuid: generateUuid(),
        name: `item_${i + 1}`,
        email: `user${i + 1}@example.com`,
        created_at: new Date().toISOString(),
        is_active: i % 2 === 0,
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
async function GetUser(call, callback) {
  try {
    const user = await db.getUser(call.request.id);
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
        ? user.created_at.toISOString()
        : String(user.created_at),
    });
  } catch (err) {
    callback(err);
  }
}

/**
 * Scenario 4: Complex database query (JOIN + aggregation)
 */
async function GetComplexOrders(call, callback) {
  try {
    const days = call.request.days || 30;
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
async function GetCacheValue(call, callback) {
  try {
    const key = call.request.key;
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

module.exports = {
  Health,
  GetJsonItems,
  GetUser,
  GetComplexOrders,
  GetCacheValue,
};
