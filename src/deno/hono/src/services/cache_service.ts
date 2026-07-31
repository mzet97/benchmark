/**
 * Cache Service - Redis Real
 * Implements Redis cache operations
 */

import { Redis } from 'https://deno.land/x/redis@v0.29.0/mod.ts';

export interface CacheService {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, ttl: number): Promise<void>;
  getOrSet(key: string, factory: () => Promise<string>, ttl: number): Promise<string>;
  healthCheck(): Promise<boolean>;
}

export class RedisCacheService implements CacheService {
  private redis: any;
  private connectionString: string;

  constructor() {
    this.connectionString = Deno.env.get('REDIS_URL') || (() => { throw new Error('REDIS_URL is required'); })();
  }

  async init(): Promise<void> {
    console.log('🔌 Connecting to Redis...', this.connectionString.replace(/\/\/.*@/, '//***:***@'));

    // Test connection
    this.redis = new Redis(this.connectionString);
    await this.redis.ping();
    console.log('✅ Redis connected successfully');
  }

  async get(key: string): Promise<string | null> {
    try {
      return await this.redis.get(key);
    } catch (error) {
      console.error('Cache get error:', error);
      return null;
    }
  }

  async set(key: string, value: string, ttl: number): Promise<void> {
    try {
      await this.redis.setex(key, ttl, value);
    } catch (error) {
      console.error('Cache set error:', error);
      throw error;
    }
  }

  async getOrSet(key: string, factory: () => Promise<string>, ttl: number): Promise<string> {
    const cached = await this.get(key);
    if (cached !== null && cached !== undefined) {
      return cached;
    }

    const value = await factory();
    await this.set(key, value, ttl);
    return value;
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.redis.ping();
      return true;
    } catch (error) {
      console.error('❌ Redis health check failed:', error);
      return false;
    }
  }
}
