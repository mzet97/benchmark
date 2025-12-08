import { Client } from "../../deps.ts";
import { DatabaseConfig } from "../types.ts";

export class DatabaseService {
  private client: Client | null = null;
  private config: DatabaseConfig;

  constructor(config?: Partial<DatabaseConfig>) {
    const connectionString = Deno.env.get("DATABASE_URL");
    if (!connectionString) {
      throw new Error("DATABASE_URL is required");
    }

    this.config = {
      connectionString,
      minPool: parseInt(Deno.env.get("DB_POOL_MIN") || "5"),
      maxPool: parseInt(Deno.env.get("DB_POOL_MAX") || "25"),
      timeout: parseInt(Deno.env.get("DB_TIMEOUT") || "30000"),
      ...config,
    };
  }

  async init() {
    this.client = new Client(this.config.connectionString);
    await this.client.connect();
    console.log("Database connected");
  }

  async close() {
    if (this.client) {
      await this.client.end();
      console.log("Database disconnected");
    }
  }

  async getUser(userId: number) {
    if (!this.client) throw new Error("Database not initialized");

    const query = `
      SELECT id, email, first_name, last_name, created_at
      FROM users
      WHERE id = $1
    `;

    const result = await this.client.queryObject(query, [userId]);
    return result.rows[0] || null;
  }

  async getComplexOrders(days: number) {
    if (!this.client) throw new Error("Database not initialized");

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

    const result = await this.client.queryObject(query, [days]);
    return result.rows;
  }

  async healthCheck(): Promise<boolean> {
    if (!this.client) return false;

    try {
      await this.client.queryObject("SELECT 1");
      return true;
    } catch (error) {
      console.error("Database health check failed:", error);
      return false;
    }
  }
}

export const databaseService = new DatabaseService();
