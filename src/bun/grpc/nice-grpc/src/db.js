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

pool.on("error", (err) => {
  console.error("Unexpected PostgreSQL pool error:", err);
});

async function query(text, params) {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;
  if (duration > 100) {
    console.log(`Slow query (${duration}ms): ${text}`);
  }
  return result;
}

async function healthCheck() {
  try {
    const result = await pool.query("SELECT 1");
    return result.rows.length > 0 ? "connected" : "disconnected";
  } catch (err) {
    console.error("Database health check failed:", err.message);
    return "disconnected";
  }
}

async function close() {
  await pool.end();
}

module.exports = { query, healthCheck, close, pool };
