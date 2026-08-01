import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { swagger } from '@elysiajs/swagger';
import pino from 'pino';
import { databaseService } from './services/database';
import { cacheService } from './services/cache';
import { healthRoutes } from './routes/health';
import { jsonRoutes } from './routes/json';
import { databaseRoutes } from './routes/database';
import { cacheRoutes } from './routes/cache';

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

// Create Elysia app
const app = new Elysia()
  .use(cors({
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
  }))
  .use(swagger({
    path: '/docs',
    documentation: {
      info: {
        title: 'Benchmark API - Bun Elysia',
        version: '1.0.0',
        description: 'High-performance REST API benchmark using Bun runtime with Elysia framework'
      }
    }
  }))
  // Request logging middleware
  .derive(({ request }) => {
    const start = Date.now();
    return {
      request,
      startTime: start
    };
  })
  .onAfterHandle(({ request, response, startTime }) => {
    const processTime = Date.now() - startTime;
    logger.info('Request processed', {
      method: request.method,
      url: request.url,
      status: response?.status || 200,
      processTime: `${processTime}ms`
    });
  })
  // Error handler
  .onError(({ request, error, code }) => {
    logger.error('Request error', {
      method: request.method,
      url: request.url,
      error: error.message,
      code
    });

    return {
      error: 'Internal server error',
      message: process.env.DEBUG === 'true' ? error.message : 'An error occurred'
    };
  })
  // Register routes
  .use(healthRoutes)
  .use(jsonRoutes)
  .use(databaseRoutes)
  .use(cacheRoutes)
  // Root endpoint
  .get('/', () => {
    return {
      name: 'Benchmark API - Bun Elysia',
      version: '1.0.0',
      description: 'High-performance REST API benchmark',
      runtime: 'Bun',
      framework: 'Elysia',
      endpoints: {
        health: '/health',
        json: '/json',
        db_simple: '/db/simple?id=1',
        db_complex: '/db/complex?days=30',
        cache: '/cache?key=test',
        docs: '/docs'
      },
      status: 'running'
    };
  });

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

    logger.info('Starting Benchmark API (Bun + Elysia)...');

    app.listen({
      port: PORT,
      hostname: HOST,
      // Several worker processes bind the same port; the kernel balances
      // accepted connections across them. See src/index.ts.
      reusePort: true
    });

    logger.info(`Server listening on http://${HOST}:${PORT}`);
    logger.info('Documentation available at /docs');
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

start();

export default app;
