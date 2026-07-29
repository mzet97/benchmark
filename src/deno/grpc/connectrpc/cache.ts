import Redis from "ioredis";

const redis = new Redis({
  host: Deno.env.get("REDIS_HOST") || "localhost",
  port: parseInt(Deno.env.get("REDIS_PORT") || "6379"),
  password: Deno.env.get("REDIS_PASSWORD") || "",
  db: parseInt(Deno.env.get("REDIS_DB") || "0"),
  maxRetriesPerRequest: 3,
});

export async function checkHealth(): Promise<string> {
  try {
    await redis.ping();
    return "connected";
  } catch {
    return "disconnected";
  }
}

export async function getValue(key: string) {
  const value = await redis.get(key);
  if (value !== null) {
    const ttl = await redis.ttl(key);
    return { value, cached: true, ttl: ttl > 0 ? ttl : 0 };
  }

  // Cache miss: generate a value, store it, return
  const generatedValue = `generated_value_${key}_${Date.now()}`;
  await redis.set(key, generatedValue, "EX", 3600);
  return { value: generatedValue, cached: false, ttl: 3600 };
}

export async function close(): Promise<void> {
  await redis.quit();
}
