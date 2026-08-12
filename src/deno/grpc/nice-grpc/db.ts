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

interface QueryResult {
  rows: Record<string, unknown>[];
}

export async function query(text: string, params: unknown[]): Promise<QueryResult> {
  const client = await pool.connect();
  try {
    const result = await client.queryObject(text, params);
    return { rows: result.rows as Record<string, unknown>[] };
  } finally {
    client.release();
  }
}

export async function healthCheck(): Promise<string> {
  try {
    const client = await pool.connect();
    await client.queryObject("SELECT 1");
    client.release();
    return "connected";
  } catch {
    return "disconnected";
  }
}

export async function close(): Promise<void> {
  await pool.end();
}
