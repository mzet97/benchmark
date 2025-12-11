import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseService } from './services/database.service';
import { CacheService } from './services/cache.service';
import { HealthController } from './controllers/health.controller';
import { JsonController } from './controllers/json.controller';
import { DatabaseController } from './controllers/database.controller';
import { CacheController } from './controllers/cache.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
  ],
  controllers: [
    HealthController,
    JsonController,
    DatabaseController,
    CacheController,
  ],
  providers: [
    DatabaseService,
    CacheService,
  ],
})
export class AppModule {}
