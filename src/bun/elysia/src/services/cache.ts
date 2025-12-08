import { createClient } from 'redis';
import pino from 'pino';

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  }
});

export class CacheService {
  private client: ReturnType<typeof createClient> | null = null;

  async init() {
    const redisUrl = process.env.REDIS_URL;

    if (!redisUrl) {
      throw new Error('REDIS_URL is required');
    }

    this.client = createClient({
      url: redisUrl,
      socket: {
        reconnectStrategy: (retries) => Math.min(retries * 50, 1000)
      }
    });

    this.client.on('error', (err) => {
      logger.error('Redis client error', err);
    });

    this.client.on('connect', () => {
      logger.info('Redis client connected');
    });

    await this.client.connect();
    logger.info('Redis initialized');
  }

  async close() {
    if (this.client) {
      await this.client.disconnect();
      logger.info('Redis disconnected');
    }
  }

  async get(key: string): Promise<string | null> {
    if (!this.client) throw new Error('Redis not initialized');
    return await this.client.get(key);
  }

  async set(key: string, value: string, ttlSeconds: number = 300) {
    if (!this.client) throw new Error('Redis not initialized');
    await this.client.setEx(key, ttlSeconds, value);
  }

  async ping(): Promise<boolean> {
    if (!this.client) return false;

    try {
      await this.client.ping();
      return true;
    } catch (error) {
      logger.error('Redis health check failed', error);
      return false;
    }
  }
}

export const cacheService = new CacheService();
