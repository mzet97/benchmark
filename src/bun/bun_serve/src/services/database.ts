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

      const result = await this.client.query(
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

  async getComplexQuery(days: number): Promise<any[]> {
    try {
      if (!this.client) throw new Error('Database not initialized');

      const result = await this.client.query(`
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

      return result.rows;
    } catch (error) {
      console.error('Error fetching complex query:', error);
      return [];
    }
  }
}

export const databaseService = new DatabaseService();
