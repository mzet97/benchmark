import { Redis } from "../deps.ts";
import { CacheConfig } from "../types.ts";

export class CacheService {
  private redis: Redis | null = null;
  private config: CacheConfig;

  constructor(config?: Partial<CacheConfig>) {
    const redisUrl = Deno.env.get("REDIS_URL");
    if (!redisUrl) {
      throw new Error("REDIS_URL is required");
    }

    // Parse Redis URL
    // Format: redis://:password@host:port or redis://host:port
    const url = new URL(redisUrl);
    const password = url.password || undefined;

    this.config = {
      host: url.hostname,
      port: parseInt(url.port || "6379"),
      password,
      ttl: parseInt(Deno.env.get("CACHE_TTL") || "300"),
      ...config,
    };
  }

  async init() {
    this.redis = new Redis({
      hostname: this.config.host,
      port: this.config.port,
      password: this.config.password,
    });

    await this.redis.ping();
    console.log("Redis connected");
  }

  async close() {
    if (this.redis) {
      await this.redis.quit();
      console.log("Redis disconnected");
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.redis) throw new Error("Redis not initialized");
    return await this.redis.get(key);
  }

  async set(key: string, value: string, ttlSeconds?: number) {
    if (!this.redis) throw new Error("Redis not initialized");
    const ttl = ttlSeconds || this.config.ttl;
    await this.redis.setex(key, ttl, value);
  }

  async ping(): Promise<boolean> {
    if (!this.redis) return false;

    try {
      await this.redis.ping();
      return true;
    } catch (error) {
      console.error("Redis health check failed:", error);
      return false;
    }
  }
}

export const cacheService = new CacheService();
