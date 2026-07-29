import Redis from "ioredis";

const redis = new Redis({
  host: Deno.env.get("REDIS_HOST") || "localhost",
  port: parseInt(Deno.env.get("REDIS_PORT") || "6379"),
  password: Deno.env.get("REDIS_PASSWORD") || "",
  db: parseInt(Deno.env.get("REDIS_DB") || "0"),
  maxRetriesPerRequest: 3,
});

export async function healthCheck(): Promise<string> {
  try {
    const result = await redis.ping();
    return result === "PONG" ? "connected" : "disconnected";
  } catch (err) {
    console.error("Cache health check failed:", (err as Error).message);
    return "disconnected";
  }
}

export async function get(key: string): Promise<{ value: string | null; hit: boolean }> {
  try {
    const value = await redis.get(key);
    return { value, hit: value !== null };
  } catch (err) {
    console.error("Cache get error:", (err as Error).message);
    return { value: null, hit: false };
  }
}

export async function set(key: string, value: string, ttlSeconds = 300): Promise<boolean> {
  try {
    await redis.set(key, value, "EX", ttlSeconds);
    return true;
  } catch (err) {
    console.error("Cache set error:", (err as Error).message);
    return false;
  }
}

export async function close(): Promise<void> {
  await redis.quit();
}
