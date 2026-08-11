// The TTL is part of the response contract and must match what is written
// to Redis. See contracts/rest/canonical-payloads.md.
const CACHE_TTL_SECONDS = 300;

import pino from 'pino';

// Level from the ConfigMap (LOG_LEVEL=error), and no pino-pretty transport.
//
// pino-pretty is a development formatter: it reparses every record and applies
// ANSI colouring, in a transport worker, for each log call. Together with the
// per-request `logger.info('Cache operation', ...)` that used to sit below the
// getOrSet call, it put a formatted, colourised write on the measured path --
// the 2-3x that deploy/k3s/base/configmap.yaml sets LOG_LEVEL=error to avoid,
// and invariante 1 in docs/ACTION_PLAN.md. Only the error path logs now.
const logger = pino({ level: process.env.LOG_LEVEL || 'error' });

export async function cacheHandler(req, res) {
  try {
    const key = req.query.key || 'test_key';

    // No `await new Promise(resolve => setTimeout(resolve, 50))` on the miss
    // path. It was hidden work on the measured path (invariante 1). On the
    // kotlin/spring sibling that carried the same 50 ms sleep the cache read
    // never hit, so every request paid it and /cache measured 1,962 rps against
    // the 100-connections / 50 ms ceiling of 2,000 -- the number described the
    // delay, not Redis. And even where the read does hit, the measurement
    // window (30 s warmup + 5 x 60 s = 330 s) outlives the 300 s TTL, so the key
    // expires mid-sequence and one repetition eats the stall.
    const result = await req.app.locals.cacheService.getOrSet(
      key,
      async () => `Cached value for ${key} at ${new Date().toISOString()}`,
      CACHE_TTL_SECONDS
    );

    res.json({
      key: key,
      value: result.value,
      cached: result.cached,
      ttl: CACHE_TTL_SECONDS,
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
