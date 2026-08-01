import { Client } from "../deps.ts";
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

    // The normative SQL aliases the columns to the contract names, so the row
    // is the response body. The previous version also omitted `age`.
    // See contracts/rest/canonical-payloads.md.
    const query = `
      SELECT id, email, first_name AS "firstName", last_name AS "lastName",
             age, created_at AS "createdAt"
      FROM users
      WHERE id = $1
    `;

    const result = await this.client.queryObject(query, [userId]);
    return result.rows[0] || null;
  }

  // Renamed from getComplexOrders: routes/database.ts called
  // getComplexQuery, which did not exist, so /db/complex threw a TypeError on
  // every request.
  //
  // Normative SQL, see contracts/rest/canonical-payloads.md. The previous
  // query returned individual order rows instead of per-user aggregates and
  // wrote INTERVAL '%s days' -- the %s is inside the quotes and is therefore
  // not a placeholder, so Postgres read the literal string "%s days".
  async getComplexQuery(days: number) {
    if (!this.client) throw new Error("Database not initialized");

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
