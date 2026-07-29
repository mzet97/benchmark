const crypto = require('crypto');
const db = require('./db');
const cache = require('./cache');

const VERSION = process.env.APP_VERSION || '1.0.0';

// Scenario 1: Health check
async function health(call, callback) {
  try {
    const [dbStatus, cacheStatus] = await Promise.all([
      db.healthCheck(),
      cache.healthCheck(),
    ]);

    callback(null, {
      status: 'ok',
      version: VERSION,
      timestamp: new Date().toISOString(),
      database: dbStatus,
      cache: cacheStatus,
    });
  } catch (err) {
    console.error('Health check error:', err);
    callback(null, {
      status: 'degraded',
      version: VERSION,
      timestamp: new Date().toISOString(),
      database: 'unknown',
      cache: 'unknown',
    });
  }
}

// Scenario 2: JSON serialization (1000 items)
async function getJsonItems(call, callback) {
  try {
    const limit = call.request.limit > 0 ? call.request.limit : 1000;
    const items = [];

    for (let i = 1; i <= limit; i++) {
      items.push({
        id: i,
        uuid: crypto.randomUUID(),
        name: `Item ${i}`,
        email: `user${i}@benchmark.com`,
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
    console.error('GetJsonItems error:', err);
    callback({
      code: 13, // INTERNAL
      message: `Failed to generate items: ${err.message}`,
    });
  }
}

// Scenario 3: Simple database query
async function getUser(call, callback) {
  try {
    const { id } = call.request;
    const result = await db.query(
      'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      callback({
        code: 5, // NOT_FOUND
        message: `User with id ${id} not found`,
      });
      return;
    }

    const user = result.rows[0];
    callback(null, {
      id: user.id,
      email: user.email || '',
      first_name: user.first_name || '',
      last_name: user.last_name || '',
      age: user.age || 0,
      created_at: user.created_at ? user.created_at.toISOString() : '',
    });
  } catch (err) {
    console.error('GetUser error:', err);
    callback({
      code: 13, // INTERNAL
      message: `Failed to get user: ${err.message}`,
    });
  }
}

// Scenario 4: Complex database query (JOIN + aggregation)
async function getComplexOrders(call, callback) {
  try {
    const days = call.request.days > 0 ? call.request.days : 30;

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

    const data = result.rows.map((row) => ({
      user_id: row.user_id,
      user_name: row.user_name || '',
      total_orders: parseInt(row.total_orders) || 0,
      total_value: parseFloat(row.total_value) || 0,
      average_order_value: parseFloat(row.average_order_value) || 0,
    }));

    callback(null, {
      period_days: days,
      total_users: data.length,
      data,
    });
  } catch (err) {
    console.error('GetComplexOrders error:', err);
    callback({
      code: 13, // INTERNAL
      message: `Failed to get complex orders: ${err.message}`,
    });
  }
}

// Scenario 5: Cache hit/miss
async function getCacheValue(call, callback) {
  try {
    const { key } = call.request;
    const result = await cache.get(key);

    if (result.hit) {
      // Cache hit
      callback(null, {
        key,
        value: result.value,
        cached: true,
        ttl: 300,
        timestamp: new Date().toISOString(),
      });
    } else {
      // Cache miss - generate a value and store it
      const value = `value-${Date.now()}`;
      await cache.set(key, value, 300);

      callback(null, {
        key,
        value,
        cached: false,
        ttl: 300,
        timestamp: new Date().toISOString(),
      });
    }
  } catch (err) {
    console.error('GetCacheValue error:', err);
    callback({
      code: 13, // INTERNAL
      message: `Failed to get cache value: ${err.message}`,
    });
  }
}

module.exports = {
  health,
  getJsonItems,
  getUser,
  getComplexOrders,
  getCacheValue,
};
