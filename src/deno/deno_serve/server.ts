/**
 * Benchmark API - Deno.serve
 * High-performance REST API benchmark implementation using Deno.serve
 * Uses REAL PostgreSQL and Redis (NOT mock data)
 */

// Import services and models
import { PostgresDatabaseService } from './src/services/database_service.ts';
import { RedisCacheService } from './src/services/cache_service.ts';
import { mapUserToDto } from './src/models/user.ts';
import type { ComplexOrderResponse } from './src/models/complex_result.ts';

const PORT = parseInt(Deno.env.get('PORT') || '3000');

// Initialize services
const databaseService = new PostgresDatabaseService();
const cacheService = new RedisCacheService();

// Initialize database and cache connections
await databaseService.init();
await cacheService.init();

// Health endpoint
const healthHandler = async (req: Request): Promise<Response> => {
  const dbHealthy = await databaseService.healthCheck();
  const cacheHealthy = await cacheService.healthCheck();

  return new Response(JSON.stringify({
    status: 'healthy',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    database: dbHealthy ? 'connected' : 'disconnected',
    cache: cacheHealthy ? 'connected' : 'disconnected'
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

// JSON endpoint
const jsonHandler = async (req: Request): Promise<Response> => {
  const items = Array.from({ length: 1000 }, (_, i) => ({
    id: i + 1,
    name: 'Item ' + (i + 1),
    value: 'Value ' + (i + 1),
    timestamp: new Date().toISOString()
  }));

  return new Response(JSON.stringify({
    items,
    count: items.length
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

// Simple database query
const dbSimpleHandler = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const id = url.searchParams.get('id');

  if (!id) {
    return new Response(JSON.stringify({
      error: 'Bad Request',
      message: 'id parameter is required'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  const userId = parseInt(id);
  if (isNaN(userId) || userId <= 0) {
    return new Response(JSON.stringify({
      error: 'Bad Request',
      message: 'id must be a positive number'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  console.log('Database simple query executed', { user_id: userId });

  const user = await databaseService.getUserById(userId);

  if (!user) {
    return new Response(JSON.stringify({
      error: 'Not Found',
      message: `User with id ${userId} not found`
    }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  const userDto = mapUserToDto(user);

  return new Response(JSON.stringify({
    user: userDto,
    timestamp: new Date().toISOString()
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

// Complex database query
const dbComplexHandler = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const days = parseInt(url.searchParams.get('days') || '30');

  if (isNaN(days) || days <= 0 || days > 365) {
    return new Response(JSON.stringify({
      error: 'Bad Request',
      message: 'days must be between 1 and 365'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  console.log('Database complex query executed', { days });

  const results = await databaseService.getComplexQuery(days);

  const response: ComplexOrderResponse = {
    period_days: days,
    total_users: results.length,
    data: results,
    timestamp: new Date().toISOString()
  };

  return new Response(JSON.stringify(response), {
    headers: { 'Content-Type': 'application/json' }
  });
};

// Cache endpoint
const cacheHandler = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const key = url.searchParams.get('key') || 'test';

  if (!key) {
    return new Response(JSON.stringify({
      error: 'Bad Request',
      message: 'key parameter is required'
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  console.log('Cache request for key:', key);

  const value = await cacheService.getOrSet(
    key,
    async () => {
      // Simulate some work
      await new Promise(resolve => setTimeout(resolve, 50));
      return `Cached value for ${key} at ${new Date().toISOString()}`;
    },
    300 // 5 minutes TTL
  );

  return new Response(JSON.stringify({
    key: key,
    value: value,
    cached: !value.includes(`Cached value for ${key}`),
    timestamp: new Date().toISOString()
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

// Root endpoint
const rootHandler = async (req: Request): Promise<Response> => {
  return new Response(JSON.stringify({
    name: 'Benchmark API - Deno Deno.serve',
    version: '1.0.0',
    description: 'High-performance REST API benchmark',
    runtime: 'Deno',
    framework: 'Deno.serve',
    database: 'PostgreSQL',
    cache: 'Redis',
    endpoints: {
      health: '/health',
      json: '/json',
      db_simple: '/db/simple?id=1',
      db_complex: '/db/complex?days=30',
      cache: '/cache?key=test'
    },
    status: 'running'
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

const healthzHandler = async (req: Request): Promise<Response> => {
  return new Response(JSON.stringify({ status: 'ok' }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

// Router
const handleRequest = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const path = url.pathname;

  try {
    switch (path) {
      case '/':
        return await rootHandler(req);
      case '/health':
        return await healthHandler(req);
      case '/json':
        return await jsonHandler(req);
      case '/db/simple':
        return await dbSimpleHandler(req);
      case '/db/complex':
        return await dbComplexHandler(req);
      case '/cache':
        return await cacheHandler(req);
      case '/healthz':
        return await healthzHandler(req);
      default:
        return new Response('Not Found', { status: 404 });
    }
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      message: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

console.log(`🚀 Server starting on port ${PORT}`);
console.log(`✅ Using PostgreSQL: spsql.home.arpa:5432/benchmark_api`);
console.log(`✅ Using Redis: redis.home.arpa:30379`);

Deno.serve({
  port: PORT,
  handler: handleRequest,
});
