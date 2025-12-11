import { Controller, Get } from '@nestjs/common';
import { DatabaseService } from '../services/database.service';
import { CacheService } from '../services/cache.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly databaseService: DatabaseService,
    private readonly cacheService: CacheService,
  ) {}

  @Get()
  async healthCheck() {
    const dbHealthy = await this.databaseService.healthCheck();
    const cacheHealthy = await this.cacheService.healthCheck();

    return {
      status: dbHealthy && cacheHealthy ? 'healthy' : 'unhealthy',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: dbHealthy ? 'healthy' : 'unhealthy',
      cache: cacheHealthy ? 'healthy' : 'unhealthy',
    };
  }

  @Get('live')
  getLive() {
    return { status: 'alive', timestamp: new Date().toISOString() };
  }
}
