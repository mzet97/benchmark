import { databaseService } from '../services/database.ts';
import { cacheService } from '../services/cache.ts';
import type { HealthStatus } from '../types.ts';

export async function healthHandler(request: Request): Promise<Response> {
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

    return new Response(JSON.stringify(health), {
      status: statusCode,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      status: 'error',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: 'unhealthy',
      cache: 'unhealthy',
      error: 'Internal server error',
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }
}

export async function healthzHandler(request: Request): Promise<Response> {
  return new Response(JSON.stringify({ status: 'ok' }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}
