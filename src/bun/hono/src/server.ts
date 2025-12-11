import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import pino from 'pino';
import { databaseService } from './services/database.ts';
import { cacheService } from './services/cache.ts';
import { healthRoutes } from './routes/health.ts';
import { jsonRoutes } from './routes/json.ts';
import { databaseRoutes } from './routes/database.ts';
import { cacheRoutes } from './routes/cache.ts';

// Configure logger
const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  },
  level: process.env.LOG_LEVEL || 'info'
});

// Create Hono app
const app = new Hono();

// Request logging middleware
app.use('*', async (c, next) => {
  const start = Date.now();
  await next();
  const processTime = Date.now() - start;
  logger.info('Request processed', {
    method: c.req.method,
    url: c.req.url,
    status: c.res.status,
    processTime: `${processTime}ms`
  });
});

// Error handler
app.onError((error, c) => {
  logger.error('Request error', {
    method: c.req.method,
    url: c.req.url,
    error: error.message,
  });

  return c.json({
    error: 'Internal server error',
    message: process.env.DEBUG === 'true' ? error.message : 'An error occurred'
  }, 500);
});

// Root endpoint
app.get('/', (c) => {
  return c.json({
    name: 'Benchmark API - Bun Hono',
    version: '1.0.0',
    description: 'High-performance REST API benchmark',
    runtime: 'Bun',
    framework: 'Hono',
    endpoints: {
      health: '/health',
      json: '/json',
      db_simple: '/db/simple?id=1',
      db_complex: '/db/complex?days=30',
      cache: '/cache?key=test'
    },
    status: 'running'
  });
});

// Register routes
app.route('/', healthRoutes);
app.route('/', jsonRoutes);
app.route('/', databaseRoutes);
app.route('/', cacheRoutes);

// Server configuration
const PORT = parseInt(process.env.PORT || '3000');
const HOST = process.env.HOST || '0.0.0.0';

// Graceful shutdown
const shutdown = async () => {
  logger.info('Shutting down server...');

  try {
    await databaseService.close();
    await cacheService.close();
    logger.info('Services closed successfully');
    process.exit(0);
  } catch (error) {
    logger.error('Error during shutdown', error);
    process.exit(1);
  }
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// Start server
const start = async () => {
  try {
    logger.info('Initializing services...');

    await databaseService.init();
    await cacheService.init();

    logger.info('Starting Benchmark API (Bun + Hono)...');

    serve({
      fetch: app.fetch,
      port: PORT,
      hostname: HOST,
    });

    logger.info(`Server listening on http://${HOST}:${PORT}`);
    logger.info('Benchmark API ready');
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

start();

export default app;
