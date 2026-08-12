import { Pool } from "postgres";

// Pool size from the contract, not a literal. index.ts already divides
// DB_POOL_MAX by the worker count and injects the per-worker share into the child
// environment, so this reads the value as-is -- dividing again would be wrong, and
// hardcoding it made that arithmetic dead code. With BENCH_CPUS=40 the old
// literals meant up to 40 x 25 = 1000 PostgreSQL connections against the
// contract's 32, and min: 5 held 200 open from startup. See invariante 3 in
// docs/ACTION_PLAN.md and Fase 9.13.
const poolMaxRaw = Number.parseInt(Deno.env.get("DB_POOL_MAX") ?? "", 10);
const poolMax = Number.isInteger(poolMaxRaw) && poolMaxRaw > 0 ? poolMaxRaw : 32;


const pool = new Pool(
  {
    hostname: Deno.env.get("DB_HOST") || "localhost",
    port: parseInt(Deno.env.get("DB_PORT") || "5432"),
    database: Deno.env.get("DB_NAME") || "benchmark",
    user: Deno.env.get("DB_USER") || "benchmark",
    password: Deno.env.get("DB_PASSWORD") || "benchmark",
  },
  // Contract value, not a literal 20. These three implementations have no
  // multi-process bootstrap (see the note in server.ts), so the whole pod is one
  // process and this is the pod's entire budget.
  poolMax,
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
