const REDIS_HOST = Deno.env.get("REDIS_HOST") || "localhost";
const REDIS_PORT = parseInt(Deno.env.get("REDIS_PORT") || "6379");
const REDIS_PASSWORD = Deno.env.get("REDIS_PASSWORD") || "";
const REDIS_DB = parseInt(Deno.env.get("REDIS_DB") || "0");

let conn: Deno.TcpConn | null = null;
let connected = false;

async function ensureConnection(): Promise<Deno.TcpConn> {
  if (conn && connected) {
    try {
      return conn;
    } catch {
      connected = false;
    }
  }

  conn = await Deno.connect({ hostname: REDIS_HOST, port: REDIS_PORT });
  connected = true;

  if (REDIS_PASSWORD) {
    await sendCommand(`AUTH ${REDIS_PASSWORD}`);
  }
  if (REDIS_DB !== 0) {
    await sendCommand(`SELECT ${REDIS_DB}`);
  }

  return conn;
}

async function sendCommand(cmd: string): Promise<string> {
  const c = await ensureConnection();
  const encoder = new TextEncoder();
  const parts = cmd.split(" ");
  let resp = `*${parts.length}\r\n`;
  for (const part of parts) {
    resp += `$${encoder.encode(part).length}\r\n${part}\r\n`;
  }
  await c.write(encoder.encode(resp));

  const buf = new Uint8Array(4096);
  const n = await c.read(buf);
  if (!n) throw new Error("No response from Redis");
  return new TextDecoder().decode(buf.subarray(0, n));
}

function parseBulkString(resp: string): string | null {
  if (resp.startsWith("$-1")) return null;
  const lines = resp.split("\r\n");
  return lines[1] || null;
}

export async function checkHealth(): Promise<string> {
  try {
    const result = await sendCommand("PING");
    return result.includes("PONG") ? "connected" : "disconnected";
  } catch {
    connected = false;
    return "disconnected";
  }
}

export async function getValue(key: string): Promise<{
  value: string;
  cached: boolean;
  ttl: number;
}> {
  const result = await sendCommand(`GET ${key}`);
  const value = parseBulkString(result);

  if (value !== null) {
    const ttlResult = await sendCommand(`TTL ${key}`);
    const ttlLines = ttlResult.split("\r\n");
    const ttl = parseInt(ttlLines[1] || "0");
    return { value, cached: true, ttl: ttl > 0 ? ttl : 0 };
  }

  // Cache miss: generate a value, store it, return
  const generatedValue = `generated_value_${key}_${Date.now()}`;
  await sendCommand(`SET ${key} ${generatedValue} EX 3600`);
  return { value: generatedValue, cached: false, ttl: 3600 };
}

export async function close(): Promise<void> {
  if (conn) {
    try {
      conn.close();
    } catch {
      // ignore
    }
    conn = null;
    connected = false;
  }
}
