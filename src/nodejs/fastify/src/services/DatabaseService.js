import pg from 'pg';

const { Pool } = pg;

class DatabaseService {
  constructor() {
    const connectionString = process.env.DATABASE_URL || (() => { throw new Error('DATABASE_URL is required'); })();

    this.pool = new Pool({
      connectionString,
      max: 25,
      min: 5,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });

    this.pool.on('error', (err) => {
      console.error('Unexpected database error:', err);
      process.exit(-1);
    });
  }

  async findUserById(id) {
    const query = {
      // The normative SQL aliases its columns to the contract names, so the row
      // needs no per-field mapping. See contracts/rest/canonical-payloads.md.
      text: 'SELECT id, email, first_name AS "firstName", last_name AS "lastName", '
          + 'age, created_at AS "createdAt" FROM users WHERE id = $1',
      values: [id]
    };

    try {
      const result = await this.pool.query(query);
      return result.rows[0] || null;
    } catch (error) {
      console.error('Error fetching user:', error);
      throw error;
    }
  }

  async findComplexOrders(days) {
    const query = {
      // Normative SQL. The previous query selected an
      // email/order_count/avg_amount/days_since_first_order shape nothing else
      // used, and ordered without a tiebreak.
      text: `
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
      `,
      values: [days]
    };

    try {
      const result = await this.pool.query(query);
      return result.rows;
    } catch (error) {
      console.error('Error fetching complex orders:', error);
      throw error;
    }
  }

  async healthCheck() {
    try {
      const result = await this.pool.query('SELECT 1');
      return result.rows.length > 0;
    } catch (error) {
      console.error('Database health check failed:', error);
      return false;
    }
  }

  async close() {
    await this.pool.end();
  }
}

export default DatabaseService;
