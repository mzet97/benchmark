import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { Pool } from 'pg';

@Injectable()
export class DatabaseService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(DatabaseService.name);
  private pool: Pool;

  onModuleInit() {
    // Pool size from the contract, not a literal. main.ts already divides
    // DB_POOL_MAX by the worker count and injects the per-worker share into the
    // child environment, so this reads the value as-is -- dividing again would be
    // wrong, and hardcoding it made that arithmetic dead code. With BENCH_CPUS=40
    // the old literals meant up to 40 x 25 = 1000 Postgres connections against
    // the contract's 32, and `min: 5` held 200 of them open from startup. See
    // invariante 3 in docs/ACTION_PLAN.md and Fase 9.10.
    const poolMaxRaw = Number.parseInt(process.env.DB_POOL_MAX ?? '', 10);
    const poolMax = Number.isInteger(poolMaxRaw) && poolMaxRaw > 0 ? poolMaxRaw : 32;

    this.pool = new Pool({
      connectionString: process.env.DATABASE_URL || (() => { throw new Error('DATABASE_URL is required'); })(),
      max: poolMax,
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
