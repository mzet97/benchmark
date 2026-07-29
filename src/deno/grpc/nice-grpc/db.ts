import { Pool } from "postgres";

const pool = new Pool(
  {
    host: Deno.env.get("DB_HOST") || "localhost",
    port: parseInt(Deno.env.get("DB_PORT") || "5432"),
    database: Deno.env.get("DB_NAME") || "benchmark",
    user: Deno.env.get("DB_USER") || "benchmark",
    password: Deno.env.get("DB_PASSWORD") || "benchmark",
  },
  20, // max connections
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
