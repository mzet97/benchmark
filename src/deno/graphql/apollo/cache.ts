import Redis from "ioredis";

const REDIS_URL = Deno.env.get("REDIS_URL") ||
  "redis://:Admin@123@redis.home.arpa:30379";

const redis = new Redis(REDIS_URL);

export async function checkCache(): Promise<boolean> {
  try {
    await redis.ping();
    return true;
  } catch {
    return false;
  }
}

export async function getCache(key: string): Promise<string | null> {
  return await redis.get(key);
}

export async function setCache(key: string, value: string, ttl = 300) {
  await redis.setex(key, ttl, value);
}
