import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');
  
  const port = process.env.PORT || 3000;
  const host = '0.0.0.0';
  
  app.setGlobalPrefix('api');
  
  app.enableCors({
    origin: true,
    credentials: true,
  });
  
  await app.listen(port, host);
  logger.log(`Server running on http://${host}:${port}`);
  logger.log('Benchmark API ready');
}

bootstrap();
