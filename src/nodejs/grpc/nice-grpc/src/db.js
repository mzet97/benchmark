import { Pool } from 'pg';

// Pool size from the contract, not a literal. The cluster bootstrap in index.js
// already divides DB_POOL_MAX by the worker count and injects the per-worker
// share into the child environment, so this reads the value as-is -- dividing
// again here would be wrong, and hardcoding it made the bootstrap's arithmetic
// dead code. With 40 workers the old literal meant up to 40 x 20 = 800 Postgres
// connections against the contract's 32. See invariante 3 in
// docs/ACTION_PLAN.md and Fase 9.10.
const poolMaxRaw = Number.parseInt(process.env.DB_POOL_MAX ?? '', 10);
const poolMax = Number.isInteger(poolMaxRaw) && poolMaxRaw > 0 ? poolMaxRaw : 32;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'benchmark',
  user: process.env.DB_USER || 'benchmark',
  password: process.env.DB_PASSWORD || 'benchmark',
  max: poolMax,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('Unexpected PostgreSQL pool error:', err);
});

async function query(text, params) {
  const start = Date.now();
  const result = await pool.query(text, params);
  // No slow-query log. /db/complex runs at roughly 860 rps against 100
  // connections, i.e. ~116 ms per query, so every single complex query crossed
  // the 100 ms threshold and wrote its full multi-line SQL to stdout
  // synchronously. A bare console.log is not suppressed by LOG_LEVEL=error, and
  // no other implementation in the matrix logs per query. Invariante 1 in
  // docs/ACTION_PLAN.md.
  return result;
}

async function healthCheck() {
  try {
    const result = await pool.query('SELECT 1');
    return result.rows.length > 0 ? 'connected' : 'disconnected';
  } catch (err) {
    console.error('Database health check failed:', err.message);
    return 'disconnected';
  }
}

async function close() {
  await pool.end();
}

export { query, healthCheck, close, pool };