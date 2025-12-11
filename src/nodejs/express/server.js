import express from 'express';
import pino from 'pino';
import pinoHttp from 'pino-http';
import DatabaseService from './services/DatabaseService.js';
import CacheService from './services/CacheService.js';
import { healthHandler, healthzHandler } from './routes/health.js';
import { jsonHandler } from './routes/json.js';
import { dbSimpleHandler, dbComplexHandler } from './routes/database.js';
import { cacheHandler } from './routes/cache.js';

// Configure logger
const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  },
  level: process.env.LOG_LEVEL || 'info'
});

// Create Express app
const app = express();
const PORT = parseInt(process.env.PORT || '3000');
const HOST = process.env.HOST || '0.0.0.0';

// Add middleware
app.use(pinoHttp({ logger }));
app.use(express.json());

// Initialize services
const databaseService = new DatabaseService();
const cacheService = new CacheService();

// Make services available to routes
app.locals.databaseService = databaseService;
app.locals.cacheService = cacheService;

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Benchmark API - Node.js Express',
    version: '1.0.0',
    description: 'High-performance REST API benchmark',
    runtime: 'Node.js',
    framework: 'Express',
    endpoints: {
      health: '/health',
      healthz: '/healthz',
      json: '/json',
      db_simple: '/db/simple?id=1',
      db_complex: '/db/complex?days=30',
      cache: '/cache?key=test'
    },
    status: 'running'
  });
});

// Register routes
app.get('/health', healthHandler);
app.get('/healthz', healthzHandler);
app.get('/json', jsonHandler);
app.get('/db/simple', dbSimpleHandler);
app.get('/db/complex', dbComplexHandler);
app.get('/cache', cacheHandler);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.originalUrl} not found`
  });
});

// Global error handler
app.use((error, req, res, next) => {
  req.log?.error('Unhandled error', error);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.DEBUG === 'true' ? error.message : 'An error occurred'
  });
});

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

    logger.info('Starting Benchmark API (Node.js + Express)...');

    const server = app.listen(PORT, HOST, () => {
      logger.info(`Server listening on http://${HOST}:${PORT}`);
      logger.info('Benchmark API ready');
    });

    // Store server reference for graceful shutdown
    app.locals.server = server;
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

start();

export default app;
