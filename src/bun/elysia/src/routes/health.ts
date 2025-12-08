import { Elysia } from 'elysia';
import { databaseService } from '../services/database';
import { cacheService } from '../services/cache';
import { HealthStatus } from '../types';

export const healthRoutes = new Elysia()
  .get('/health', async () => {
    const dbHealthy = await databaseService.healthCheck();
    const cacheHealthy = await cacheService.ping();

    const health: HealthStatus = {
      status: dbHealthy && cacheHealthy ? 'healthy' : 'unhealthy',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: dbHealthy ? 'healthy' : 'unhealthy',
      cache: cacheHealthy ? 'healthy' : 'unhealthy'
    };

    return health;
  })
  .get('/healthz', () => {
    return { status: 'ok' };
  });
