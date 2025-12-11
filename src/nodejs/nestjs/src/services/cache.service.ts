import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { createClient } from 'redis';

@Injectable()
export class CacheService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(CacheService.name);
  private client: ReturnType<typeof createClient>;

  onModuleInit() {
    this.client = createClient({
      url: process.env.REDIS_URL || 'redis://:Admin@123@redis.home.arpa:30379'
    });

    this.client.on('error', (err) => this.logger.error('Redis Client Error', err));
    this.client.on('connect', () => this.logger.log('Redis connected'));

    this.client.connect();
    this.logger.log('Cache service initialized');
  }

  onModuleDestroy() {
    if (this.client) {
      this.client.quit();
      this.logger.log('Cache service closed');
    }
  }

  async get(key: string): Promise<string | null> {
    try {
      return await this.client.get(key);
    } catch (error) {
      this.logger.error('Error getting from cache', error);
      throw error;
    }
  }

  async set(key: string, value: string, ttl: number = 300): Promise<void> {
    try {
      await this.client.setEx(key, ttl, value);
    } catch (error) {
      this.logger.error('Error setting cache', error);
      throw error;
    }
  }

  async healthCheck(): Promise<boolean> {
    try {
      await this.client.ping();
      return true;
    } catch (error) {
      this.logger.error('Cache health check failed', error);
      return false;
    }
  }
}
