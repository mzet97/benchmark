'use strict';

const db = require('./db');
const cache = require('./cache');

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

    jsonItems: async (_parent, { limit = 1000 }) => {
      const items = [];
      for (let i = 0; i < limit; i++) {
        items.push({
          id: i + 1,
          uuid: `item-${i + 1}-uuid`,
          name: `Item ${i + 1}`,
          email: `item${i + 1}@example.com`,
          createdAt: new Date().toISOString(),
          isActive: i % 2 === 0
        });
      }
      return {
        items,
        count: items.length,
        timestamp: new Date().toISOString()
      };
    },

    user: async (_parent, { id }) => {
      const result = await db.query(
        'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
        [id]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        email: row.email,
        firstName: row.first_name,
        lastName: row.last_name,
        age: row.age,
        createdAt: row.created_at.toISOString()
      };
    },

    complexOrders: async (_parent, { days = 30 }) => {
      const result = await db.query(`
        SELECT
          u.id AS user_id,
          u.first_name || ' ' || u.last_name AS user_name,
          COUNT(o.id) AS total_orders,
          COALESCE(SUM(o.amount), 0) AS total_value,
          CASE WHEN COUNT(o.id) > 0
            THEN COALESCE(SUM(o.amount), 0) / COUNT(o.id)
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

    cache: async (_parent, { key }) => {
      const value = await cache.get(key);
      const ttl = await cache.ttl(key);

      if (value !== null) {
        return {
          key,
          value,
          cached: true,
          ttl: ttl >= 0 ? ttl : 0
        };
      }

      const generatedValue = `value-for-${key}`;
      await cache.set(key, generatedValue, { EX: 300 });

      return {
        key,
        value: generatedValue,
        cached: false,
        ttl: 300
      };
    }
  }
};

module.exports = { resolvers };
