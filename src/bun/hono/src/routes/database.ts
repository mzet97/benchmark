import { Hono } from 'hono';
import { databaseService } from '../services/database.ts';

export const databaseRoutes = new Hono();

// Simple database query
databaseRoutes.get('/db/simple', async (c) => {
  try {
    const idParam = c.req.query('id');

    if (!idParam) {
      return c.json({
        error: 'Bad Request',
        message: 'id parameter is required',
      }, 400);
    }

    const userId = parseInt(idParam);
    if (isNaN(userId)) {
      return c.json({
        error: 'Bad Request',
        message: 'id must be a number',
      }, 400);
    }

    const user = await databaseService.getUser(userId);

    if (!user) {
      return c.json({
        error: 'Not Found',
        message: 'User not found',
      }, 404);
    }

    return c.json({ user });
  } catch (error) {
    return c.json({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }, 500);
  }
});

// Complex database query
databaseRoutes.get('/db/complex', async (c) => {
  try {
    const daysParam = c.req.query('days') || '30';
    const days = parseInt(daysParam);

    if (isNaN(days) || days <= 0 || days > 365) {
      return c.json({
        error: 'Bad Request',
        message: 'days must be between 1 and 365',
      }, 400);
    }

    const results = await databaseService.getComplexQuery(days);

    return c.json({
      periodDays: days,
      totalUsers: results.length,
      data: results,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    return c.json({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }, 500);
  }
});
