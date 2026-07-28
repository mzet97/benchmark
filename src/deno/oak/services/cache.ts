import { redisConnect } from "../deps.ts";

export class CacheService {
  private redis: any = null;
  private host: string = "";
  private port: number = 6379;
  private password: string | undefined;

  constructor() {
    const redisUrl = Deno.env.get("REDIS_URL") || "redis://:Admin@123@redis.home.arpa:30379";
    // Parse redis://:password@host:port manually (handle @ in password)
    const afterScheme = redisUrl.split("://")[1] || "";
    const lastAt = afterScheme.lastIndexOf("@");
    const password = afterScheme.substring(1, lastAt); // skip leading ':'
    const hostPort = afterScheme.substring(lastAt + 1);
    this.host = hostPort.split(":")[0];
    this.port = parseInt(hostPort.split(":")[1] || "6379");
    this.password = password || undefined;
  }

  async init() {
    this.redis = await redisConnect({
      hostname: this.host,
      port: this.port,
      password: this.password,
    });
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
