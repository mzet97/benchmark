import Fastify from 'fastify';
import sensible from '@fastify/sensible';
import cors from '@fastify/cors';
import underPressure from '@fastify/under-pressure';

// Import routes
import healthRoutes from './routes/health.js';
import jsonRoutes from './routes/json.js';
import databaseRoutes from './routes/database.js';
import cacheRoutes from './routes/cache.js';

// Import services
import DatabaseService from './services/DatabaseService.js';
import CacheService from './services/CacheService.js';

async function buildServer() {
  const fastify = Fastify({
    logger: {
      level: process.env.LOG_LEVEL || 'info',
      transport: process.env.NODE_ENV === 'development' ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname'
        }
      } : undefined
    },
    trustProxy: true,
    bodyLimit: 1024 * 1024, // 1MB
    requestTimeout: 30000, // 30 seconds
  });

  // Register plugins
  await fastify.register(sensible);

  await fastify.register(cors, {
    origin: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE']
  });

  await fastify.register(underPressure, {
    maxEventLoopDelay: 200,
    maxHeapUsedBytes: 1000 * 1024 * 1024,
    maxRssBytes: 1000 * 1024 * 1024,
    exposeStatusRoute: '/status',
    healthCheck: async () => {
      const dbHealthy = await fastify.dbService.healthCheck();
      const cacheHealthy = await fastify.cacheService.healthCheck();
      return dbHealthy && cacheHealthy;
    },
    healthCheckInterval: 5000,
  });

  // Initialize services
  fastify.decorate('dbService', new DatabaseService());
  fastify.decorate('cacheService', new CacheService());

  // Register routes
  await fastify.register(healthRoutes);
  await fastify.register(jsonRoutes);
  await fastify.register(databaseRoutes);
  await fastify.register(cacheRoutes);

  // Health check route
  fastify.get('/healthz', async () => {
    return { status: 'ok' };
  });

  // Root route
  fastify.get('/', async () => {
    return {
      name: 'Benchmark API',
      version: '1.0.0',
      endpoints: {
        health: '/health',
        json: '/json',
        db_simple: '/db/simple?id=1',
        db_complex: '/db/complex?days=30',
        cache: '/cache?key=test',
        docs: '/docs'
      }
    };
  });

  // Error handler
  fastify.setErrorHandler((error, request, reply) => {
    fastify.log.error(error);

    if (error.validation) {
      reply.code(400);
      return {
        error: 'Validation error',
        message: error.message,
        details: error.validation
      };
    }

    if (error.statusCode) {
      reply.code(error.statusCode);
      return {
        error: error.message
      };
    }

    reply.code(500);
    return {
      error: 'Internal server error'
    };
  });

  return fastify;
}

async function start() {
  try {
    const fastify = await buildServer();

    const port = process.env.PORT || 8080;
    const host = process.env.HOST || '0.0.0.0';

    await fastify.listen({ port, host });

    console.log(`🚀 Server listening at http://${host}:${port}`);
    console.log(`📚 Documentation available at http://${host}:${port}/docs`);

    // Graceful shutdown
    const gracefulShutdown = async (signal) => {
      console.log(`\n${signal} received, shutting down gracefully...`);
      await fastify.close();
      await fastify.dbService.close();
      await fastify.cacheService.close();
      process.exit(0);
    };

    process.on('SIGINT', gracefulShutdown);
    process.on('SIGTERM', gracefulShutdown);

  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

start();
