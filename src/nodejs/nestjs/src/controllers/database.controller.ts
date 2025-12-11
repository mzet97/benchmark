import { Controller, Get, Query } from '@nestjs/common';
import { DatabaseService } from '../services/database.service';

@Controller('db')
export class DatabaseController {
  constructor(private readonly databaseService: DatabaseService) {}

  @Get('simple')
  async getSimple(@Query('id') id: string) {
    if (!id) {
      return {
        error: 'Bad Request',
        message: 'id parameter is required',
      };
    }

    const userId = parseInt(id);
    if (isNaN(userId)) {
      return {
        error: 'Bad Request',
        message: 'id must be a number',
      };
    }

    const user = await this.databaseService.findUserById(userId);

    if (!user) {
      return {
        error: 'Not Found',
        message: 'User not found',
      };
    }

    return { user };
  }

  @Get('complex')
  async getComplex(
    @Query('days') days: string = '30',
    @Query('userId') userId: string = '1',
  ) {
    const parsedDays = parseInt(days);
    const parsedUserId = parseInt(userId);

    if (isNaN(parsedDays) || isNaN(parsedUserId)) {
      return {
        error: 'Bad Request',
        message: 'days and userId must be numbers',
      };
    }

    const orders = await this.databaseService.findComplexOrders(parsedDays);

    return {
      orders,
      summary: {
        total_orders: orders.length,
        user_id: parsedUserId,
        days: parsedDays,
      },
    };
  }
}
