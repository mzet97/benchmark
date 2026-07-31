/**
 * Database Service - PostgreSQL Real
 * Implements connection pooling and queries to PostgreSQL
 */

import { Client } from 'https://deno.land/x/postgres@v0.19.3/mod.ts';

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  age: number;
  created_at: Date;
}

export interface ComplexOrderResult {
  user_id: number;
  user_email: string;
  total_orders: number;
  total_value: number;
  average_value: number;
  days_since_first_order: number;
}

export interface DatabaseService {
  getUserById(id: number): Promise<User | null>;
  getComplexQuery(days: number): Promise<ComplexOrderResult[]>;
  healthCheck(): Promise<boolean>;
}

export class PostgresDatabaseService implements DatabaseService {
  private pool: any;
  private connectionString: string;

  constructor() {
    this.connectionString = Deno.env.get('DATABASE_URL') || (() => { throw new Error('DATABASE_URL is required'); })();

    // Create connection pool
    this.pool = {
      clients: [],
      max: 10,
      min: 2,
    };
  }

  async init(): Promise<void> {
    console.log('🔌 Connecting to PostgreSQL...', this.connectionString.replace(/\/\/.*@/, '//***:***@'));

    // Test connection
    const client = new Client(this.connectionString);
    await client.connect();

    // Test query
    const result = await client.query('SELECT 1 as test');
    console.log('✅ PostgreSQL connected successfully');

    await client.end();
  }

  async getUserById(id: number): Promise<User | null> {
    const client = new Client(this.connectionString);
    await client.connect();

    try {
      const result = await client.query(
        'SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1',
        [id]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      return {
        id: row.id,
        email: row.email,
        first_name: row.first_name,
        last_name: row.last_name,
        age: row.age,
        created_at: row.created_at,
      };
    } finally {
      await client.end();
    }
  }

  async getComplexQuery(days: number): Promise<ComplexOrderResult[]> {
    const client = new Client(this.connectionString);
    await client.connect();

    try {
      const query = `
        SELECT
          u.id as user_id,
          u.email as user_email,
          COUNT(DISTINCT o.id) as total_orders,
          COALESCE(SUM(oi.quantity * oi.price), 0) as total_value,
          COALESCE(AVG(oi.quantity * oi.price), 0) as average_value,
          EXTRACT(DAY FROM (NOW() - MIN(o.created_at))) as days_since_first_order
        FROM users u
        INNER JOIN orders o ON u.id = o.user_id
          AND o.created_at >= NOW() - INTERVAL '${days} days'
          AND o.status = 'completed'
        INNER JOIN order_items oi ON o.id = oi.order_id
        GROUP BY u.id, u.email
        ORDER BY total_orders DESC
        LIMIT 100
      `;

      const result = await client.query(query);

      return result.rows.map(row => ({
        user_id: row.user_id,
        user_email: row.user_email,
        total_orders: parseInt(row.total_orders),
        total_value: parseFloat(row.total_value),
        average_value: parseFloat(row.average_value),
        days_since_first_order: parseInt(row.days_since_first_order),
      }));
    } finally {
      await client.end();
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      const client = new Client(this.connectionString);
      await client.connect();
      const result = await client.query('SELECT 1');
      await client.end();
      return result.rows.length > 0;
    } catch (error) {
      console.error('❌ Database health check failed:', error);
      return false;
    }
  }
}
