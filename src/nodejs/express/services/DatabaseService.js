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
      // The previous version returned {Id, Name, Email, CreatedAt, IsActive}:
      // PascalCase, first and last name concatenated, and an IsActive flag
      // computed from the row age -- a shape no other implementation used.
      // The normative SQL aliases the columns to the contract names, so the
      // row goes out as-is. See contracts/rest/canonical-payloads.md.
      const result = await this.pool.query(
        'SELECT id, email, first_name AS "firstName", last_name AS "lastName", ' +
        'age, created_at AS "createdAt" FROM users WHERE id = $1',
        [id]
      );

      return result.rows.length === 0 ? null : result.rows[0];
    } catch (error) {
      console.error('Error fetching user:', error);
      return null;
    }
  }

  async getComplexQuery(days) {
    try {
      // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
      // query interpolated `days` straight into the SQL with a template
      // literal, selected a user_email/days_since_first_order shape nothing
      // else used, and ordered without a tiebreak.
      const result = await this.pool.query(`
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
      `, [days]);

      return result.rows.map(row => ({
        userId: parseInt(row.userId),
        userName: row.userName,
        totalOrders: parseInt(row.totalOrders),
        totalValue: parseFloat(row.totalValue),
        averageOrderValue: parseFloat(row.averageOrderValue)
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
