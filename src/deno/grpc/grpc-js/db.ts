import { Pool } from "postgres";

const pool = new Pool(
  {
    hostname: Deno.env.get("DB_HOST") || "localhost",
    port: parseInt(Deno.env.get("DB_PORT") || "5432"),
    database: Deno.env.get("DB_NAME") || "benchmark",
    user: Deno.env.get("DB_USER") || "benchmark",
    password: Deno.env.get("DB_PASSWORD") || "benchmark",
  },
  20, // max connections
  true // lazy
);

export async function checkHealth(): Promise<string> {
  try {
    const client = await pool.connect();
    await client.queryObject("SELECT 1");
    client.release();
    return "connected";
  } catch {
    return "disconnected";
  }
}

export async function getUser(id: number) {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(
      "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
      [id]
    );
    return result.rows[0] || null;
  } finally {
    client.release();
  }
}

export async function getComplexOrders(days: number) {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(
      `SELECT
         u.id AS user_id,
         u.first_name || ' ' || u.last_name AS user_name,
         COUNT(o.id) AS total_orders,
         COALESCE(SUM(o.total_amount), 0) AS total_value,
         COALESCE(AVG(o.total_amount), 0) AS average_order_value
       FROM users u
       LEFT JOIN orders o ON u.id = o.user_id
         AND o.created_at >= NOW() - ($1 || ' days')::INTERVAL
       GROUP BY u.id, u.first_name, u.last_name
       ORDER BY total_value DESC`,
      [days.toString()]
    );

    return (result.rows as Record<string, unknown>[]).map((row) => ({
      user_id: row.user_id as number,
      user_name: row.user_name as string,
      total_orders: parseInt(row.total_orders as string),
      total_value: parseFloat(row.total_value as string),
      average_order_value: parseFloat(row.average_order_value as string),
    }));
  } finally {
    client.release();
  }
}

export async function close(): Promise<void> {
  await pool.end();
}
