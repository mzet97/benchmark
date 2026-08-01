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

    // The normative SQL aliases the columns to the contract names, so the row
    // is the response body. The previous version also omitted `age`.
    // See contracts/rest/canonical-payloads.md.
    const query = `
      SELECT id, email, first_name AS "firstName", last_name AS "lastName",
             age, created_at AS "createdAt"
      FROM users
      WHERE id = $1
    `;

    const result = await this.pool.query(query, [userId]);
    return result.rows[0] || null;
  }

  // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
  // query returned individual order rows -- order_id, items_count, joined
  // through order_items -- and the route then aggregated them in JavaScript.
  // Every other implementation aggregates in the database, so this was timing
  // a different workload entirely. It also wrote INTERVAL '%s days', where the
  // %s is inside the quotes and is therefore not a placeholder at all:
  // Postgres read the literal string "%s days".
  async getComplexOrders(days: number) {
    if (!this.pool) throw new Error('Database not initialized');

    const query = `
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
    `;

    const result = await this.pool.query(query, [days]);
    return result.rows.map((row: any) => ({
      userId: parseInt(row.userId),
      userName: row.userName,
      totalOrders: parseInt(row.totalOrders),
      totalValue: parseFloat(row.totalValue),
      averageOrderValue: parseFloat(row.averageOrderValue)
    }));
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
