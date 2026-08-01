import { databaseService } from '../services/database.ts';
import type { User } from '../types.ts';

export async function dbSimpleHandler(request: Request): Promise<Response> {
  try {
    const url = new URL(request.url);
    const idParam = url.searchParams.get('id');

    if (!idParam) {
      return new Response(JSON.stringify({
        error: 'Bad Request',
        message: 'id parameter is required',
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }

    const userId = parseInt(idParam);
    if (isNaN(userId)) {
      return new Response(JSON.stringify({
        error: 'Bad Request',
        message: 'id must be a number',
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }

    const user = await databaseService.getUser(userId);

    if (!user) {
      return new Response(JSON.stringify({
        error: 'Not Found',
        message: 'User not found',
      }), {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }

    return new Response(JSON.stringify({ user }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }
}

export async function dbComplexHandler(request: Request): Promise<Response> {
  try {
    const url = new URL(request.url);
    const daysParam = url.searchParams.get('days') || '30';

    const days = parseInt(daysParam);

    if (isNaN(days) || days <= 0 || days > 365) {
      return new Response(JSON.stringify({
        error: 'Bad Request',
        message: 'days must be a number between 1 and 365',
      }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }

    const results = await databaseService.getComplexQuery(days);

    return new Response(JSON.stringify({
      periodDays: days,
      totalUsers: results.length,
      data: results,
    }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      message: 'An error occurred while processing the request',
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }
}
