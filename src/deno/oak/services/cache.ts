import { redisConnect, redisParseURL } from "../deps.ts";

export class CacheService {
  private redis: any = null;
  private options: { hostname: string; port: number; password?: string };

  constructor() {
    // Prefer discrete REDIS_HOST / REDIS_PORT / REDIS_PASSWORD env vars.
    // Passing the password directly avoids the percent-decoding issues that
    // plague REDIS_URL parsing: the password "Admin@123" percent-encoded as
    // "Admin%40123" was reaching Redis still-encoded, so auth failed with
    // WRONGPASS and crashed the worker. parseURL was supposed to decode it,
    // but it did not, so read the vars directly and only fall back to parsing
    // REDIS_URL when the discrete vars are absent.
    const host = Deno.env.get("REDIS_HOST");
    const portStr = Deno.env.get("REDIS_PORT");
    const password = Deno.env.get("REDIS_PASSWORD");
    if (host && portStr) {
      this.options = {
        hostname: host,
        port: parseInt(portStr, 10),
        password: password || undefined,
      };
    } else {
      const redisUrl = Deno.env.get("REDIS_URL") ||
        (() => { throw new Error('REDIS_URL is required when REDIS_HOST/REDIS_PORT are not set'); })();
      const parsed = redisParseURL(redisUrl);
      this.options = {
        hostname: parsed.hostname,
        port: typeof parsed.port === "string" ? parseInt(parsed.port, 10) : (parsed.port ?? 6379),
        password: parsed.password,
      };
    }
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
