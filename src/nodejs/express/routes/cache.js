import pino from 'pino';

const logger = pino({
  transport: {
    target: 'pino-pretty',
    options: { colorize: true }
  }
});

export async function cacheHandler(req, res) {
  try {
    const key = req.query.key || 'test_key';

    const result = await req.app.locals.cacheService.getOrSet(
      key,
      async () => {
        await new Promise(resolve => setTimeout(resolve, 50));
        return `Cached value for ${key} at ${new Date().toISOString()}`;
      },
      300
    );

    logger.info('Cache operation', { key, cached: result.cached });

    res.json({
      key: key,
      value: result.value,
      cached: result.cached,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Cache operation failed', error);
    res.status(500).json({
      error: 'Cache operation failed',
      message: error.message
    });
  }
}
