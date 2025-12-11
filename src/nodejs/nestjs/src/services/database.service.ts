import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private pool: Pool;

  onModuleInit() {
    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL || 'postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api',
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
      SELECT id, email, first_name, last_name, age, created_at
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
