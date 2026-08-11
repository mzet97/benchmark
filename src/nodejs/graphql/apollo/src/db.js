'use strict';

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
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'benchmark',
  max: poolMax,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000
});

// Named exports, so `import * as db from './db.js'` resolves db.query and
// db.pool. An object-literal `export { key: value }` is not valid syntax; this
// module was CommonJS and the package declares "type": "module".
export const query = (text, params) => pool.query(text, params);
export { pool };
