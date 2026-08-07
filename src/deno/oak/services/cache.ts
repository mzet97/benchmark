import { redisConnect, redisParseURL } from "../deps.ts";

export class CacheService {
  private redis: any = null;
  private options: { hostname: string; port: number; password?: string };

  constructor() {
    const redisUrl = Deno.env.get("REDIS_URL") || (() => { throw new Error('REDIS_URL is required'); })();
    // Use the redis library's own parseURL (backed by the standard URL parser)
    // instead of a hand-rolled split(). The manual parser did not percent-decode
    // the password, so REDIS_URL with password Admin%40123 was sent to Redis
    // literally and auth failed. parseURL yields the decoded password (Admin@123).
    const parsed = redisParseURL(redisUrl);
    this.options = {
      hostname: parsed.hostname,
      port: typeof parsed.port === "string" ? parseInt(parsed.port, 10) : (parsed.port ?? 6379),
      password: parsed.password,
    };
  }

  async init() {
    this.redis = await redisConnect(this.options);
    console.log("Redis connected");
  }

  async close() {
    if (this.redis) {
      await this.redis.close();
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.redis) throw new Error("Redis not initialized");
    return await this.redis.get(key);
  }

  async set(key: string, value: string, ttlSeconds: number = 300) {
    if (!this.redis) throw new Error("Redis not initialized");
    await this.redis.setex(key, ttlSeconds, value);
  }

  async ping(): Promise<boolean> {
    if (!this.redis) return false;
    try {
      const reply = await this.redis.ping();
      return reply === "PONG";
    } catch {
      return false;
    }
  }
}

export const cacheService = new CacheService();
