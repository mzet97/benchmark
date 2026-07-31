import pg from 'pg';

const { Pool } = pg;

class DatabaseService {
  constructor() {
    this.pool = null;
  }

  async init() {
    try {
      const connectionString = process.env.DATABASE_URL || (() => { throw new Error('DATABASE_URL is required'); })();

      this.pool = new Pool({
        connectionString,
        min: parseInt(process.env.DB_POOL_MIN || '5'),
        max: parseInt(process.env.DB_POOL_MAX || '25'),
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
      });

      await this.pool.query('SELECT 1');
      console.log('✅ Database connection established');
    } catch (error) {
      console.error('❌ Failed to connect to database:', error);
      throw error;
    }
  }

  async getUserById(id) {
    try {
      const result = await this.pool.query(
        'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
        [id]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const user = result.rows[0];
      return {
        Id: user.id,
        Name: `${user.first_name} ${user.last_name}`,
        Email: user.email,
        CreatedAt: user.created_at,
        IsActive: new Date(user.created_at) > new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)
      };
    } catch (error) {
      console.error('Error fetching user:', error);
      return null;
    }
  }

  async getComplexQuery(days) {
    try {
      const result = await this.pool.query(`
        SELECT u.id as user_id,
               u.email as user_email,
               COUNT(DISTINCT o.id) as total_orders,
               COALESCE(SUM(o.total_amount), 0) as total_value,
               COALESCE(AVG(o.total_amount), 0) as average_value,
               EXTRACT(DAY FROM NOW() - MIN(o.created_at)) as days_since_first_order
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
          AND o.created_at >= NOW() - INTERVAL '${days} days'
        GROUP BY u.id, u.email
        HAVING COUNT(DISTINCT o.id) > 0
        ORDER BY total_value DESC
        LIMIT 100
      `);

      return result.rows.map(row => ({
        user_id: parseInt(row.user_id),
        user_email: row.user_email,
        total_orders: parseInt(row.total_orders),
        total_value: parseFloat(row.total_value),
        average_value: parseFloat(row.average_value),
        days_since_first_order: parseInt(row.days_since_first_order) || 0
      }));
    } catch (error) {
      console.error('Error fetching complex query:', error);
      return [];
    }
  }

  async healthCheck() {
    try {
      await this.pool.query('SELECT 1');
      return true;
    } catch (error) {
      console.error('Database health check failed:', error);
      return false;
    }
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      this.pool = null;
      console.log('✅ Database connection closed');
    }
  }
}

export default DatabaseService;
