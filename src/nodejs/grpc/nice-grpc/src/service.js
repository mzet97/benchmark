import crypto from 'crypto';
import * as db from './db.js';
import * as cache from './cache.js';
import {
  CANONICAL_CREATED_AT,
  canonicalEmail,
  canonicalIsActive,
  canonicalName,
  canonicalUuid,
  itemCount,
} from './canonical.js';

const VERSION = process.env.APP_VERSION || '1.0.0';

/**
 * BenchmarkService implementation for nice-grpc.
 * nice-grpc uses async generator middleware pattern; service methods
 * receive (request, context) and return the response directly.
 */
const benchmarkService = {
  // Scenario 1: Health check
  async health(request, context) {
    try {
      const [dbStatus, cacheStatus] = await Promise.all([
        db.healthCheck(),
        cache.healthCheck(),
      ]);

      return {
        status: 'ok',
        version: VERSION,
        timestamp: new Date().toISOString(),
        database: dbStatus,
        cache: cacheStatus,
      };
    } catch (err) {
      console.error('Health check error:', err);
      return {
        status: 'degraded',
        version: VERSION,
        timestamp: new Date().toISOString(),
        database: 'unknown',
        cache: 'unknown',
      };
    }
  },

  // Scenario 2: JSON serialization (1000 items)
  async getJsonItems(request, context) {
    const count = itemCount(request.limit);
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
  async getUser(request, context) {
    const { id } = request;
    const result = await db.query(
      'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      const err = new Error(`User with id ${id} not found`);
      err.code = 5; // NOT_FOUND
      throw err;
    }

    const user = result.rows[0];
    return {
      id: user.id,
      email: user.email || '',
      first_name: user.first_name || '',
      last_name: user.last_name || '',
      age: user.age || 0,
      created_at: user.created_at ? user.created_at.toISOString() : '',
    };
  },

  // Scenario 4: Complex database query (JOIN + aggregation)
  async getComplexOrders(request, context) {
    const days = request.days > 0 ? request.days : 30;

    // Normative SQL, see contracts/rest/canonical-payloads.md. Three things
    // changed here, and each one on its own made the number incomparable:
    //
    //   * the day window was interpolated into the string as
    //     INTERVAL '${days} days'. Beyond being an injection vector, a literal
    //     baked into the SQL text gives PostgreSQL a different statement for
    //     every distinct `days`, so nothing is reused. It is now a bound
    //     parameter, which is also what the contract specifies.
    //   * LEFT JOIN plus HAVING COUNT(o.id) > 0 is a slower way of writing the
    //     INNER JOIN the contract fixes: it builds the outer rows and then
    //     discards them.
    //   * ORDER BY total_value DESC with no tiebreak returned a *different* 100
    //     rows than the contract's ORDER BY total_orders DESC, u.id, and with no
    //     tiebreak the set was not even stable between runs.
    const result = await db.query(
      `SELECT
        u.id as user_id,
        u.first_name || ' ' || u.last_name as user_name,
        COUNT(o.id) as total_orders,
        COALESCE(SUM(o.total_amount), 0)::float8 as total_value,
        COALESCE(AVG(o.total_amount), 0)::float8 as average_order_value
      FROM users u
      INNER JOIN orders o ON u.id = o.user_id
        WHERE o.created_at >= NOW() - INTERVAL '1 day' * $1
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY total_orders DESC, u.id
      LIMIT 100`,
      [days]
    );

    const data = result.rows.map((row) => ({
      user_id: row.user_id,
      user_name: row.user_name || '',
      total_orders: parseInt(row.total_orders) || 0,
      total_value: parseFloat(row.total_value) || 0,
      average_order_value: parseFloat(row.average_order_value) || 0,
    }));

    return {
      period_days: days,
      total_users: data.length,
      data,
    };
  },

  // Scenario 5: Cache hit/miss
  async getCacheValue(request, context) {
    const { key } = request;
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

export default benchmarkService;
