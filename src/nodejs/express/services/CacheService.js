import { createClient } from 'redis';

class CacheService {
  constructor() {
    this.client = null;
  }

  async init() {
    try {
      const redisUrl = process.env.REDIS_URL || (() => { throw new Error('REDIS_URL is required'); })();

      this.client = createClient({
        url: redisUrl,
        socket: {
          reconnectStrategy: (retries) => Math.min(retries * 50, 500)
        }
      });

      this.client.on('error', (err) => {
        console.error('Redis client error:', err);
      });

      this.client.on('connect', () => {
        console.log('Connected to Redis');
      });

      await this.client.connect();
    } catch (error) {
      console.error('❌ Failed to connect to Redis:', error);
      throw error;
    }
  }

  async get(key) {
    try {
      return await this.client.get(key);
    } catch (error) {
      console.error(`Error getting cache key ${key}:`, error);
      return null;
    }
  }

  async set(key, value, ttlSeconds = 300) {
    try {
      await this.client.setEx(key, ttlSeconds, value);
      return true;
    } catch (error) {
      console.error(`Error setting cache key ${key}:`, error);
      return false;
    }
  }

  async getOrSet(key, factory, ttlSeconds = 300) {
    try {
      const existing = await this.get(key);

      if (existing !== null) {
        return { value: existing, cached: true };
      }

      const value = await factory();
      await this.set(key, value, ttlSeconds);
      return { value, cached: false };
    } catch (error) {
      console.error(`Error in getOrSet for key ${key}:`, error);
      return { value: await factory(), cached: false };
    }
  }

  async ping() {
    try {
      const result = await this.client.ping();
      return result === 'PONG';
    } catch (error) {
      console.error('Cache health check failed:', error);
      return false;
    }
  }

  async close() {
    if (this.client) {
      await this.client.quit();
      this.client = null;
      console.log('✅ Redis connection closed');
    }
  }
}

export default CacheService;
