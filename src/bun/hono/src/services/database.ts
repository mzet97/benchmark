import { Client } from 'pg';
import type { DatabaseConfig } from '../types.ts';

class DatabaseService {
  private client: Client | null = null;
  private config: DatabaseConfig;

  constructor() {
    this.config = {
      url: process.env.DATABASE_URL || (() => { throw new Error('DATABASE_URL is required'); })(),
      min: parseInt(process.env.DB_POOL_MIN || '5'),
      max: parseInt(process.env.DB_POOL_MAX || '25')
    };
  }

  async init(): Promise<void> {
    try {
      this.client = new Client({
        connectionString: this.config.url,
        min: this.config.min,
        max: this.config.max,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 5000,
      });

      await this.client.connect();
      console.log('✅ Database connection established');
    } catch (error) {
      console.error('❌ Failed to connect to database:', error);
      throw error;
    }
  }

  async close(): Promise<void> {
    if (this.client) {
      await this.client.end();
      this.client = null;
      console.log('✅ Database connection closed');
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      if (!this.client) return false;
      await this.client.query('SELECT 1');
      return true;
    } catch (error) {
      console.error('Database health check failed:', error);
      return false;
    }
  }

  async getUser(id: number): Promise<any> {
    try {
      if (!this.client) throw new Error('Database not initialized');

      // The normative SQL aliases the columns to the contract names, so the
      // row is the response body. The previous version reshaped it into
      // {id, email, name, age, created_at}, concatenating the names.
      const result = await this.client.query(
        'SELECT id, email, first_name AS "firstName", last_name AS "lastName", ' +
        'age, created_at AS "createdAt" FROM users WHERE id = $1',
        [id]
      );

      return result.rows[0] || null;
    } catch (error) {
      console.error('Error fetching user:', error);
      throw error;
    }
  }

  async getComplexQuery(days: number): Promise<any[]> {
    try {
      if (!this.client) throw new Error('Database not initialized');

      // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
      // query interpolated `days` straight into the SQL, selected a
      // user_email/days_since_first_order shape nothing else used, and ordered
      // without a tiebreak.
      const result = await this.client.query(`
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

      return result.rows.map((row: any) => ({
        userId: parseInt(row.userId),
        userName: row.userName,
        totalOrders: parseInt(row.totalOrders),
        totalValue: parseFloat(row.totalValue),
        averageOrderValue: parseFloat(row.averageOrderValue)
      }));
    } catch (error) {
      console.error('Error executing complex query:', error);
      throw error;
    }
  }
}

export const databaseService = new DatabaseService();
