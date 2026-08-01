import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private pool: Pool;

  onModuleInit() {
    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL || (() => { throw new Error('DATABASE_URL is required'); })(),
      min: 5,
      max: 25,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });
    
    this.logger.log('Database connection pool initialized');
  }

  onModuleDestroy() {
    if (this.pool) {
      this.pool.end();
      this.logger.log('Database connection pool closed');
    }
  }

  async findUserById(userId: number): Promise<any> {
    const query = `
      SELECT id, email, first_name AS "firstName", last_name AS "lastName",
             age, created_at AS "createdAt"
      FROM users
      WHERE id = $1
    `;
    
    try {
      const result = await this.pool.query(query, [userId]);
      return result.rows[0] || null;
    } catch (error) {
      this.logger.error('Error fetching user', error);
      throw error;
    }
  }

  async findComplexOrders(days: number): Promise<any[]> {
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
    
    try {
      const result = await this.pool.query(query, [days]);
      return result.rows;
    } catch (error) {
      this.logger.error('Error fetching complex orders', error);
      throw error;
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      const result = await this.pool.query('SELECT 1');
      return result.rows[0] ? true : false;
    } catch (error) {
      this.logger.error('Database health check failed', error);
      return false;
    }
  }
}
