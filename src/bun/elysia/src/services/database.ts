import { Pool } from 'pg';
import pino from 'pino';

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  }
});

export class DatabaseService {
  private pool: Pool | null = null;

  async init() {
    const databaseUrl = process.env.DATABASE_URL;

    if (!databaseUrl) {
      throw new Error('DATABASE_URL is required');
    }

    this.pool = new Pool({
      connectionString: databaseUrl,
      min: parseInt(process.env.DB_POOL_MIN || '5'),
      max: parseInt(process.env.DB_POOL_MAX || '25'),
      idleTimeoutMillis: parseInt(process.env.DB_IDLE_TIMEOUT || '30000'),
      connectionTimeoutMillis: parseInt(process.env.DB_TIMEOUT || '10000'),
    });

    logger.info('Database pool initialized');
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      logger.info('Database pool closed');
    }
  }

  async getUser(userId: number) {
    if (!this.pool) throw new Error('Database not initialized');

    const query = `
      SELECT id, email, first_name, last_name, created_at
      FROM users
      WHERE id = $1
    `;

    const result = await this.pool.query(query, [userId]);
    return result.rows[0] || null;
  }

  async getComplexOrders(days: number) {
    if (!this.pool) throw new Error('Database not initialized');

    const query = `
      SELECT
        o.id as order_id,
        o.user_id,
        u.email as user_email,
        o.total_amount,
        o.created_at,
        COUNT(oi.id) as items_count
      FROM orders o
      JOIN users u ON o.user_id = u.id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.created_at >= NOW() - INTERVAL '%s days'
      GROUP BY o.id, u.email
      ORDER BY o.created_at DESC
      LIMIT 100
    `;

    const result = await this.pool.query(query, [days]);
    return result.rows;
  }

  async healthCheck(): Promise<boolean> {
    if (!this.pool) return false;

    try {
      await this.pool.query('SELECT 1');
      return true;
    } catch (error) {
      logger.error('Database health check failed', error);
      return false;
    }
  }
}

export const databaseService = new DatabaseService();
