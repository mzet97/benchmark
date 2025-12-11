import Redis from 'ioredis';
import type { CacheConfig } from '../types.ts';

class CacheService {
  private client: Redis | null = null;
  private config: CacheConfig;

  constructor() {
    this.config = {
      url: process.env.REDIS_URL || 'redis://:Admin@123@redis.home.arpa:30379',
      ttl: parseInt(process.env.CACHE_TTL || '300')
    };
  }

  async init(): Promise<void> {
    try {
      this.client = new Redis(this.config.url, {
        maxRetriesPerRequest: 3,
        retryDelayOnFailover: 100,
        enableReadyCheck: true,
        lazyConnect: true,
      });

      this.client.on('connect', () => {
        console.log('✅ Redis connection established');
      });

      this.client.on('error', (error) => {
        console.error('❌ Redis connection error:', error);
      });

      await this.client.connect();
    } catch (error) {
      console.error('❌ Failed to connect to Redis:', error);
      throw error;
    }
  }

  async close(): Promise<void> {
    if (this.client) {
      await this.client.quit();
      this.client = null;
      console.log('✅ Redis connection closed');
    }
  }

  async ping(): Promise<boolean> {
    try {
      if (!this.client) return false;
      const result = await this.client.ping();
      return result === 'PONG';
    } catch (error) {
      console.error('Redis ping failed:', error);
      return false;
    }
  }

  async get(key: string): Promise<string | null> {
    try {
      if (!this.client) return null;
      return await this.client.get(key);
    } catch (error) {
      console.error('Error getting cache key:', error);
      return null;
    }
  }

  async set(key: string, value: string, ttl?: number): Promise<boolean> {
    try {
      if (!this.client) return false;
      const expiry = ttl || this.config.ttl;
      await this.client.setex(key, expiry, value);
      return true;
    } catch (error) {
      console.error('Error setting cache key:', error);
      return false;
    }
  }

  async del(key: string): Promise<boolean> {
    try {
      if (!this.client) return false;
      await this.client.del(key);
      return true;
    } catch (error) {
      console.error('Error deleting cache key:', error);
      return false;
    }
  }
}

export const cacheService = new CacheService();
