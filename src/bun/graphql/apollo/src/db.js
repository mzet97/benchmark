import pg from "pg";

const DATABASE_URL =
  process.env.DATABASE_URL ||
  "postgresql://app:Admin@123@spsql.home.arpa:5432/benchmark_api";

const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  max: 25,
  min: 5,
});

export async function checkDatabase() {
  try {
    await pool.query("SELECT 1");
    return true;
  } catch {
    return false;
  }
}

export async function getUser(userId) {
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

export async function getComplexOrders(days) {
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
  return result.rows.map((row) => ({
    userId: row.user_id,
    userName: row.user_name,
    totalOrders: parseInt(row.total_orders),
    totalValue: parseFloat(row.total_value),
    averageOrderValue: parseFloat(row.average_order_value),
  }));
}
