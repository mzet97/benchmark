import pino from 'pino';

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  }
});

export async function healthHandler(req, res) {
  try {
    const dbHealthy = await req.app.locals.databaseService.healthCheck();
    const cacheHealthy = await req.app.locals.cacheService.ping();

    const status = dbHealthy && cacheHealthy ? 'healthy' : 'unhealthy';

    res.json({
      status,
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: dbHealthy ? 'healthy' : 'unhealthy',
      cache: cacheHealthy ? 'healthy' : 'unhealthy'
    });
  } catch (error) {
    logger.error('Health check failed', error);
    res.status(500).json({
      status: 'error',
      message: 'Health check failed'
    });
  }
}

export async function healthzHandler(req, res) {
  try {
    const dbHealthy = await req.app.locals.databaseService.healthCheck();
    const cacheHealthy = await req.app.locals.cacheService.ping();

    if (dbHealthy && cacheHealthy) {
      res.status(200).send('OK');
    } else {
      res.status(503).send('Service Unavailable');
    }
  } catch (error) {
    logger.error('Healthz check failed', error);
    res.status(503).send('Service Unavailable');
  }
}
