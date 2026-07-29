const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  database: process.env.DB_NAME || "benchmark",
  user: process.env.DB_USER || "benchmark",
  password: process.env.DB_PASSWORD || "benchmark",
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

async function checkHealth() {
  try {
    const client = await pool.connect();
    await client.query("SELECT 1");
    client.release();
    return "connected";
  } catch {
    return "disconnected";
  }
}

async function getUser(id) {
  const result = await pool.query(
    "SELECT id, email, first_name, last_name, age, created_at FROM users WHERE id = $1",
    [id]
  );
  return result.rows[0] || null;
}

async function getComplexOrders(days) {
  const result = await pool.query(
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

  return result.rows.map((row) => ({
    user_id: row.user_id,
    user_name: row.user_name,
    total_orders: parseInt(row.total_orders),
    total_value: parseFloat(row.total_value),
    average_order_value: parseFloat(row.average_order_value),
  }));
}

async function close() {
  await pool.end();
}

module.exports = { checkHealth, getUser, getComplexOrders, close };
