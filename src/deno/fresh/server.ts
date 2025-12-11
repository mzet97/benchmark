/**
 * Benchmark API - Deno Fresh
 * High-performance REST API benchmark implementation using Fresh framework
 * Uses REAL PostgreSQL and Redis (NOT mock data)
 */

import { Application } from 'https://deno.land/x/fresh@1.6.8/server.ts';
import { Router } from 'https://deno.land/x/fresh@1.6.8/server.ts';

// Import services and models
import { PostgresDatabaseService } from './src/services/database_service.ts';
import { RedisCacheService } from './src/services/cache_service.ts';
import { mapUserToDto } from './src/models/user.ts';
import type { ComplexOrderResponse } from './src/models/complex_result.ts';

const app = new Application();
const PORT = parseInt(Deno.env.get('PORT') || '3000');

// Initialize services
const databaseService = new PostgresDatabaseService();
const cacheService = new RedisCacheService();

// Initialize database and cache connections
await databaseService.init();
await cacheService.init();

// Handler functions
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

const jsonHandler = async (req: Request): Promise<Response> => {
  return new Response(JSON.stringify({
    message: 'Hello from Deno Fresh!',
    timestamp: new Date().toISOString(),
    random: Math.floor(Math.random() * 1000),
    status: 'success',
    data: {
      id: 1,
      name: 'Benchmark Test',
      active: true,
      tags: ['benchmark', 'fresh', 'deno', 'api']
    }
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

const dbSimpleHandler = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const userId = parseInt(url.searchParams.get('id') || '1');

  if (isNaN(userId) || userId <= 0) {
    return new Response(JSON.stringify({ error: 'Invalid id parameter' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  console.log('Database simple query executed', { user_id: userId });

  const user = await databaseService.getUserById(userId);

  if (!user) {
    return new Response(JSON.stringify({ error: `User with id ${userId} not found` }), {
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

const dbComplexHandler = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const days = parseInt(url.searchParams.get('days') || '30');

  if (isNaN(days) || days <= 0 || days > 365) {
    return new Response(JSON.stringify({ error: 'Days must be between 1 and 365' }), {
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

const cacheHandler = async (req: Request): Promise<Response> => {
  const url = new URL(req.url);
  const key = url.searchParams.get('key') || 'test_key';

  if (!key) {
    return new Response(JSON.stringify({ error: 'Key parameter is required' }), {
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

const rootHandler = async (req: Request): Promise<Response> => {
  return new Response(JSON.stringify({
    name: 'Benchmark API - Deno Fresh',
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
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
};

const healthzHandler = async (req: Request): Promise<Response> => {
  return new Response('OK', { status: 200 });
};

// Router
app.get('/', rootHandler);
app.get('/health', healthHandler);
app.get('/json', jsonHandler);
app.get('/db/simple', dbSimpleHandler);
app.get('/db/complex', dbComplexHandler);
app.get('/cache', cacheHandler);
app.get('/healthz', healthzHandler);

console.log(`🚀 Server starting on port ${PORT}`);
console.log(`✅ Using PostgreSQL: spsql.home.arpa:5432/benchmark_api`);
console.log(`✅ Using Redis: redis.home.arpa:30379`);

app.listen(PORT);
