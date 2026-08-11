import pino from 'pino';

// Level from the ConfigMap (LOG_LEVEL=error), and no pino-pretty transport.
// pino-pretty is a development formatter: it reparses every record and applies
// ANSI colouring in a transport worker. With a log call per request that put a
// formatted, colourised write on the measured path -- invariante 1 in
// docs/ACTION_PLAN.md, and the 2-3x that LOG_LEVEL=error exists to avoid.
const logger = pino({ level: process.env.LOG_LEVEL || 'error' });

export async function dbSimpleHandler(req, res) {
  try {
    const userId = req.query.id;

    if (!userId) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'id parameter is required'
      });
    }

    const id = parseInt(userId);
    if (isNaN(id) || id <= 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'id must be a positive number'
      });
    }

    const user = await req.app.locals.databaseService.getUserById(id);

    if (!user) {
      return res.status(404).json({
        error: 'Not Found',
        message: `User with id ${id} not found`
      });
    }

    res.json(user);
  } catch (error) {
    logger.error('Database simple query failed', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
}

export async function dbComplexHandler(req, res) {
  try {
    const days = parseInt(req.query.days) || 30;

    if (days <= 0 || days > 365) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'days must be between 1 and 365'
      });
    }

    const data = await req.app.locals.databaseService.getComplexQuery(days);

    res.json({
      periodDays: days,
      totalUsers: data.length,
      data: data
    });
  } catch (error) {
    logger.error('Database complex query failed', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
}
