import { Hono } from 'hono';
import { databaseService } from '../services/database.ts';
import { cacheService } from '../services/cache.ts';
import type { HealthStatus } from '../types.ts';

export const healthRoutes = new Hono();

// Health check endpoint
healthRoutes.get('/health', async (c) => {
  try {
    const dbHealthy = await databaseService.healthCheck();
    const cacheHealthy = await cacheService.ping();

    const health: HealthStatus = {
      status: dbHealthy && cacheHealthy ? 'healthy' : 'unhealthy',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: dbHealthy ? 'healthy' : 'unhealthy',
      cache: cacheHealthy ? 'healthy' : 'unhealthy',
    };

    const statusCode = dbHealthy && cacheHealthy ? 200 : 503;

    return c.json(health, statusCode);
  } catch (error) {
    return c.json({
      status: 'error',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: 'unhealthy',
      cache: 'unhealthy',
      error: 'Internal server error',
    }, 500);
  }
});

// Healthz endpoint
healthRoutes.get('/healthz', (c) => {
  return c.json({ status: 'ok' });
});
