'use strict';

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

const resolvers = {
  Query: {
    health: async () => {
      let dbStatus = 'ok';
      let cacheStatus = 'ok';

      try {
        await db.query('SELECT 1');
      } catch {
        dbStatus = 'error';
      }

      try {
        await cache.ping();
      } catch {
        cacheStatus = 'error';
      }

      return {
        status: 'ok',
        version: VERSION,
        timestamp: new Date().toISOString(),
        database: dbStatus,
        cache: cacheStatus
      };
    },

    jsonItems: async (_, { limit = 1000 }) => {
      const count = itemCount(limit);
      const items = [];
      for (let i = 0; i < count; i++) {
        items.push({
          id: i,
          uuid: canonicalUuid(i),
          name: canonicalName(i),
          email: canonicalEmail(i),
          createdAt: CANONICAL_CREATED_AT,
          isActive: i % 2 === 0
        });
      }
      return {
        items,
        count: items.length,
        timestamp: new Date().toISOString()
      };
    },

    // Goes straight to Postgres, with no Redis layer in front of it.
    //
    // This resolver used to read "user:{id}" from Redis, return the parsed JSON
    // on a hit, and write through on a miss. No other implementation of this
    // field caches: the apollo and yoga siblings in this same directory query the
    // database on every call, and neither contracts/graphql/schema.graphql nor
    // contracts/rest/canonical-payloads.md mentions caching here. The benchmark
    // drives the field with a repeating id, so after the first request every
    // later one was answered from Redis -- this implementation's number measured
    // a Redis GET while every peer's measured a Postgres query.
    //
    // The write was also broken in a way that made it permanent. node-redis v4
    // takes options as an object, `set(key, value, { EX: 60 })`; passing
    // 'EX', 60 positionally makes the third argument the string 'EX' and drops
    // the 60, so the key was written with **no TTL at all**. The 60-second
    // expiry that might have limited the damage never existed.
    user: async (_, { id }) => {
      const result = await db.query(
        'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
        [id]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      const user = {
        id: row.id,
        email: row.email,
        firstName: row.first_name,
        lastName: row.last_name,
        age: row.age,
        createdAt: row.created_at.toISOString()
      };

      return user;
    },

    complexOrders: async (_, { days = 30 }) => {
      const result = await db.query(`
        SELECT
          u.id AS user_id,
          u.first_name || ' ' || u.last_name AS user_name,
          COUNT(o.id) AS total_orders,
          COALESCE(SUM(o.total_amount), 0) AS total_value,
          CASE WHEN COUNT(o.id) > 0
            THEN COALESCE(SUM(o.total_amount), 0) / COUNT(o.id)
            ELSE 0
          END AS average_order_value
        FROM users u
        LEFT JOIN orders o ON o.user_id = u.id
          AND o.created_at >= NOW() - ($1 || ' days')::INTERVAL
        GROUP BY u.id, u.first_name, u.last_name
        ORDER BY total_value DESC
      `, [String(days)]);

      const data = result.rows.map(row => ({
        userId: row.user_id,
        userName: row.user_name,
        totalOrders: parseInt(row.total_orders, 10),
        totalValue: parseFloat(row.total_value),
        averageOrderValue: parseFloat(row.average_order_value)
      }));

      return {
        periodDays: days,
        totalUsers: data.length,
        data
      };
    },

    cache: async (_, { key }) => {
      const value = await cache.get(key);
      const ttl = await cache.ttl(key);

      return {
        key,
        value: value || '',
        cached: value !== null,
        ttl: ttl >= 0 ? ttl : 0
      };
    }
  }
};

export { resolvers };