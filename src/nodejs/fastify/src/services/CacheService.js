import { createClient } from 'redis';

class CacheService {
  constructor() {
    const redisUrl = process.env.REDIS_URL || 'redis://:Admin@123@redis.home.arpa:30379';

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
  }

  async connect() {
    if (!this.client.isOpen) {
      await this.client.connect();
    }
  }

  async get(key) {
    try {
      await this.connect();
      return await this.client.get(key);
    } catch (error) {
      console.error(`Error getting cache key ${key}:`, error);
      return null;
    }
  }

  async set(key, value, ttlSeconds = 300) {
    try {
      await this.connect();
      await this.client.setEx(key, ttlSeconds, value);
      return true;
    } catch (error) {
      console.error(`Error setting cache key ${key}:`, error);
      return false;
    }
  }

  async getOrSet(key, newValue, ttlSeconds = 300) {
    try {
      await this.connect();
      const existing = await this.get(key);

      if (existing !== null) {
        return { value: existing, source: 'cache' };
      }

      await this.set(key, newValue, ttlSeconds);
      return { value: newValue, source: 'generated' };
    } catch (error) {
      console.error(`Error in getOrSet for key ${key}:`, error);
      return { value: newValue, source: 'generated' };
    }
  }

  async healthCheck() {
    try {
      await this.connect();
      const result = await this.client.ping();
      return result === 'PONG';
    } catch (error) {
      console.error('Cache health check failed:', error);
      return false;
    }
  }

  async close() {
    if (this.client.isOpen) {
      await this.client.quit();
    }
  }
}

export default CacheService;
