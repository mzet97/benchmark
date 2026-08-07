import { Controller, Get, Query } from '@nestjs/common';
import { CacheService } from '../services/cache.service';

@Controller('cache')
export class CacheController {
  constructor(private readonly cacheService: CacheService) {}

  @Get()
  async getCache(
    @Query('key') key: string = 'test',
    @Query('ttl') ttl: string = '300',
  ) {
    const parsedTtl = parseInt(ttl);
    const cachedValue = await this.cacheService.get(key);

    if (cachedValue !== null) {
      return {
        key,
        value: cachedValue,
        cached: true,
        ttl: parsedTtl,
        timestamp: new Date().toISOString(),
      };
    }

    const value = 'cached_data_' + key + '_' + Date.now();
    await this.cacheService.set(key, value, parsedTtl);

    return {
      key,
      value,
      cached: false,
      ttl: parsedTtl,
      timestamp: new Date().toISOString(),
    };
  }
}
