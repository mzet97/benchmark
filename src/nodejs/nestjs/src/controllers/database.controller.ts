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

    // The contract returns the user object itself, not an envelope, and the
    // normative SQL already aliases the columns to the contract names.
    return user;
  }

  // The previous version answered {orders, summary: {...}} and took a userId
  // query parameter no other implementation accepted, which also meant it was
  // parsing an argument the others were not.
  // See contracts/rest/canonical-payloads.md.
  @Get('complex')
  async getComplex(@Query('days') days: string = '30') {
    const parsedDays = parseInt(days);

    if (isNaN(parsedDays) || parsedDays <= 0 || parsedDays > 365) {
      return {
        error: 'Bad Request',
        message: 'days must be between 1 and 365',
      };
    }

    const data = await this.databaseService.findComplexOrders(parsedDays);

    return {
      periodDays: parsedDays,
      totalUsers: data.length,
      data,
    };
  }
}
