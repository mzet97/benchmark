import { Hono } from 'hono';
import pino from 'pino';
import { databaseService } from './services/database.ts';
import { cacheService } from './services/cache.ts';
import { healthRoutes } from './routes/health.ts';
import { jsonRoutes } from './routes/json.ts';
import { databaseRoutes } from './routes/database.ts';
import { cacheRoutes } from './routes/cache.ts';

// Configure logger
// pino-pretty spawns a worker thread and formats every line. It is a
// development aid, not something to run during measurement, so it is only
// wired up at debug/trace. LOG_LEVEL comes from the shared ConfigMap and
// defaults to error. See docs/ACTION_PLAN.md, Fase 3.4.
const logLevel = process.env.LOG_LEVEL || 'error';
const logger = pino(
  logLevel === 'debug' || logLevel === 'trace'
    ? { level: logLevel, transport: { target: 'pino-pretty', options: { colorize: true } } }
    : { level: logLevel }
);

// Create Hono app
const app = new Hono();

// No request logging middleware.
//
// It wrapped every request in two Date.now() calls and a logger.info with an
// object literal. The LOG_LEVEL=error from the ConfigMap suppresses the output
// but not the middleware, the timing or the allocation, and only 7 of the 100
// implementations carried request logging at all -- so the ranking rewarded
// whoever left it out. Invariante 1 in docs/ACTION_PLAN.md; the same middleware
// was removed from nodejs/express and disabled in nodejs/fastify
// (disableRequestLogging). Errors are still logged, in app.onError below.

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
const PORT = parseInt(process.env.PORT || '8080');
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

    Bun.serve({
      fetch: app.fetch,
      port: PORT,
      hostname: HOST,
      // Several worker processes bind the same port; the kernel balances
      // accepted connections across them. See src/index.ts.
      reusePort: true,
    });

    logger.info(`Server listening on http://${HOST}:${PORT}`);
    logger.info('Benchmark API ready');
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

start();
