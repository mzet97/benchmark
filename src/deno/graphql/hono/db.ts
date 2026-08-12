import pg from "pg";

const DATABASE_URL = Deno.env.get("DATABASE_URL") || (() => { throw new Error('DATABASE_URL is required'); })();

// Pool size from the contract, not a literal. index.ts already divides
// DB_POOL_MAX by the worker count and injects the per-worker share into the child
// environment, so this reads the value as-is -- dividing again would be wrong, and
// hardcoding it made that arithmetic dead code. With BENCH_CPUS=40 the old
// literals meant up to 40 x 25 = 1000 PostgreSQL connections against the
// contract's 32, and min: 5 held 200 open from startup. See invariante 3 in
// docs/ACTION_PLAN.md and Fase 9.13.
const poolMaxRaw = Number.parseInt(Deno.env.get("DB_POOL_MAX") ?? "", 10);
const poolMax = Number.isInteger(poolMaxRaw) && poolMaxRaw > 0 ? poolMaxRaw : 32;

const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  max: poolMax,
});

export async function checkDatabase(): Promise<boolean> {
  try {
    await pool.query("SELECT 1");
    return true;
  } catch {
    return false;
  }
}

export async function getUser(userId: number) {
  const result = await pool.query(
    "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
    [userId]
  );
  if (result.rows.length === 0) return null;
  const row = result.rows[0];
  return {
    id: row.id,
    email: row.email,
    firstName: row.first_name,
    lastName: row.last_name,
    age: row.age,
    createdAt: row.created_at.toISOString(),
  };
}

export async function getComplexOrders(days: number) {
  const result = await pool.query(
    `SELECT
      u.id as user_id,
      CONCAT(u.first_name, ' ', u.last_name) as user_name,
      COUNT(DISTINCT o.id) as total_orders,
      COALESCE(SUM(o.total_amount), 0) as total_value,
      COALESCE(AVG(o.total_amount), 0) as average_order_value
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id
      AND o.created_at >= NOW() - make_interval(days => $1)
      AND o.status = 'completed'
    LEFT JOIN order_items oi ON o.id = oi.order_id
    GROUP BY u.id, u.first_name, u.last_name
    ORDER BY total_value DESC
    LIMIT 100`,
    [days]
  );
  return result.rows.map((row: any) => ({
    userId: row.user_id,
    userName: row.user_name,
    totalOrders: parseInt(row.total_orders),
    totalValue: parseFloat(row.total_value),
    averageOrderValue: parseFloat(row.average_order_value),
  }));
}
