import { Elysia } from 'elysia';
import { databaseService } from '../services/database';
import { ComplexOrderResult } from '../types';

export const databaseRoutes = new Elysia()
  .get('/db/simple', async ({ request }) => {
    const url = new URL(request.url);
    const id = url.searchParams.get('id');

    if (!id) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'id parameter is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const userId = parseInt(id);
    if (isNaN(userId)) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'id must be a number' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const user = await databaseService.getUser(userId);

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Not Found', message: 'User not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify(user), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  })
  .get('/db/complex', async ({ request }) => {
    const url = new URL(request.url);
    const daysParam = url.searchParams.get('days');
    const days = daysParam ? parseInt(daysParam) : 30;

    if (isNaN(days) || days < 0) {
      return new Response(
        JSON.stringify({ error: 'Bad Request', message: 'days must be a positive number' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const data = await databaseService.getComplexOrders(days);

    const result: ComplexOrderResult = {
      periodDays: days,
      totalUsers: data.length,
      data
    };

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  });
