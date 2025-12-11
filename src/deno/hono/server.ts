/**
 * Benchmark API - Deno Hono
 * High-performance REST API benchmark implementation using Hono framework
 * Uses REAL PostgreSQL and Redis (NOT mock data)
 */

import { Hono } from 'https://deno.land/x/hono@v3.12.5/mod.ts';
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { logger } from 'https://deno.land/x/hono@v3.12.5/middleware/logger/index.ts';
import { prettyJSON } from 'https://deno.land/x/hono@v3.12.5/middleware/pretty-json/index.ts';
import { cors } from 'https://deno.land/x/hono@v3.12.5/middleware/cors/index.ts';

// Import services and models
import { PostgresDatabaseService } from './src/services/database_service.ts';
import { RedisCacheService } from './src/services/cache_service.ts';
import { mapUserToDto } from './src/models/user.ts';
import type { ComplexOrderResponse } from './src/models/complex_result.ts';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', prettyJSON());
app.use('*', cors());

const PORT = parseInt(Deno.env.get('PORT') || '3000');

// Initialize services
const databaseService = new PostgresDatabaseService();
const cacheService = new RedisCacheService();

// Initialize database and cache connections
await databaseService.init();
await cacheService.init();

// Health check endpoint
app.get('/health', async (c: any) => {
  const dbHealthy = await databaseService.healthCheck();
  const cacheHealthy = await cacheService.healthCheck();

  return c.json({
    status: 'healthy',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    database: dbHealthy ? 'connected' : 'disconnected',
    cache: cacheHealthy ? 'connected' : 'disconnected'
  });
});

// Simple JSON endpoint
app.get('/json', (c: any) => {
  return c.json({
    message: 'Hello from Deno Hono!',
    timestamp: new Date().toISOString(),
    random: Math.floor(Math.random() * 1000),
    status: 'success',
    data: {
      id: 1,
      name: 'Benchmark Test',
      active: true,
      tags: ['benchmark', 'hono', 'deno', 'api']
    }
  });
});

// Simple database query endpoint
app.get('/db/simple', async (c: any) => {
  const userId = parseInt(c.req.query('id') || '1');

  if (isNaN(userId) || userId <= 0) {
    return c.json({ error: 'Invalid id parameter' }, 400);
  }

  console.log('Database simple query executed', { user_id: userId });

  const user = await databaseService.getUserById(userId);

  if (!user) {
    return c.json({ error: `User with id ${userId} not found` }, 404);
  }

  const userDto = mapUserToDto(user);

  return c.json({
    user: userDto,
    timestamp: new Date().toISOString()
  });
});

// Complex database query endpoint
app.get('/db/complex', async (c: any) => {
  const days = parseInt(c.req.query('days') || '30');

  if (isNaN(days) || days <= 0 || days > 365) {
    return c.json({ error: 'Days must be between 1 and 365' }, 400);
  }

  console.log('Database complex query executed', { days });

  const results = await databaseService.getComplexQuery(days);

  const response: ComplexOrderResponse = {
    period_days: days,
    total_users: results.length,
    data: results,
    timestamp: new Date().toISOString()
  };

  return c.json(response);
});

// Cache endpoint
app.get('/cache', async (c: any) => {
  const key = c.req.query('key') || 'test_key';

  if (!key) {
    return c.json({ error: 'Key parameter is required' }, 400);
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

  return c.json({
    key: key,
    value: value,
    cached: !value.includes(`Cached value for ${key}`),
    timestamp: new Date().toISOString()
  });
});

// Root endpoint
app.get('/', (c: any) => {
  return c.json({
    name: 'Benchmark API - Deno Hono',
    version: '1.0.0',
    status: 'running',
    database: 'PostgreSQL',
    cache: 'Redis',
    endpoints: [
      'GET /health',
      'GET /json',
      'GET /db/simple?id=1',
      'GET /db/complex?days=30',
      'GET /cache?key=test'
    ]
  });
});

// Error handling
app.onError((err: any, c: any) => {
  console.error('Unhandled error:', err);
  return c.json({
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString()
  }, 500);
});

// Start server
console.log(`🚀 Server starting on port ${PORT}`);
console.log(`✅ Using PostgreSQL: spsql.home.arpa:5432/benchmark_api`);
console.log(`✅ Using Redis: redis.home.arpa:30379`);

serve({
  port: PORT,
  fetch: app.fetch,
});
