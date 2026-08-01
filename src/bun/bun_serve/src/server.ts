import pino from 'pino';
import { databaseService } from './services/database.ts';
import { cacheService } from './services/cache.ts';
import { healthHandler, healthzHandler } from './routes/health.ts';
import { jsonHandler } from './routes/json.ts';
import { dbSimpleHandler, dbComplexHandler } from './routes/database.ts';
import { cacheHandler } from './routes/cache.ts';

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

// Server configuration
const PORT = parseInt(process.env.PORT || '8080');
const HOST = process.env.HOST || '0.0.0.0';

// Request logger middleware
function logRequest(method: string, url: string, status: number, processTime: number) {
  logger.info('Request processed', {
    method,
    url,
    status,
    processTime: `${processTime}ms`
  });
}

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

    logger.info('Starting Benchmark API (Bun + Native Serve)...');

    const server = Bun.serve({
      port: PORT,
      hostname: HOST,
      // Several worker processes bind the same port; the kernel balances
      // accepted connections across them. See src/index.ts.
      reusePort: true,
      fetch: async (request: Request) => {
        const startTime = Date.now();
        const url = new URL(request.url);
        const method = request.method;

        try {
          let response: Response;

          // Route handling
          if (url.pathname === '/' && method === 'GET') {
            response = new Response(JSON.stringify({
              name: 'Benchmark API - Bun Native Serve',
              version: '1.0.0',
              description: 'High-performance REST API benchmark',
              runtime: 'Bun',
              framework: 'Native Serve',
              endpoints: {
                health: '/health',
                json: '/json',
                db_simple: '/db/simple?id=1',
                db_complex: '/db/complex?days=30',
                cache: '/cache?key=test'
              },
              status: 'running'
            }), {
              status: 200,
              headers: {
                'Content-Type': 'application/json',
              },
            });
          } else if (url.pathname === '/health' && method === 'GET') {
            response = await healthHandler(request);
          } else if (url.pathname === '/healthz' && method === 'GET') {
            response = await healthzHandler(request);
          } else if (url.pathname === '/json' && method === 'GET') {
            response = await jsonHandler(request);
          } else if (url.pathname === '/db/simple' && method === 'GET') {
            response = await dbSimpleHandler(request);
          } else if (url.pathname === '/db/complex' && method === 'GET') {
            response = await dbComplexHandler(request);
          } else if (url.pathname === '/cache' && method === 'GET') {
            response = await cacheHandler(request);
          } else {
            response = new Response(JSON.stringify({
              error: 'Not Found',
              message: `Route ${method} ${url.pathname} not found`
            }), {
              status: 404,
              headers: {
                'Content-Type': 'application/json',
              },
            });
          }

          const processTime = Date.now() - startTime;
          logRequest(method, url.pathname, response.status, processTime);

          return response;
        } catch (error) {
          const processTime = Date.now() - startTime;
          logger.error('Request error', {
            method,
            url: url.pathname,
            error: error.message,
            processTime: `${processTime}ms`
          });

          return new Response(JSON.stringify({
            error: 'Internal server error',
            message: process.env.DEBUG === 'true' ? error.message : 'An error occurred'
          }), {
            status: 500,
            headers: {
              'Content-Type': 'application/json',
            },
          });
        }
      },
    });

    logger.info(`Server listening on http://${HOST}:${PORT}`);
    logger.info('Benchmark API ready');
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

start();
