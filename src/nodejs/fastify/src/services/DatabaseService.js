import pg from 'pg';

const { Pool } = pg;

class DatabaseService {
  constructor() {
    const connectionString = process.env.DATABASE_URL || 'postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api';

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
      text: 'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
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
      text: `
        SELECT
          u.id as user_id,
          u.email,
          COUNT(o.id) as order_count,
          SUM(o.total_amount) as total_amount,
          AVG(o.total_amount) as avg_amount,
          EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
        FROM users u
        INNER JOIN orders o ON u.id = o.user_id
        WHERE o.created_at >= NOW() - ($1 || ' days')::INTERVAL
        GROUP BY u.id, u.email
        ORDER BY order_count DESC
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
