import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getRoot() {
    return {
      name: 'Benchmark API - Node.js NestJS',
      version: '1.0.0',
      description: 'High-performance REST API benchmark',
      runtime: 'Node.js',
      framework: 'NestJS',
      endpoints: {
        health: '/health',
        json: '/json',
        db_simple: '/db/simple?id=1',
        db_complex: '/db/complex?days=30',
        cache: '/cache?key=test'
      },
      status: 'running'
    };
  }

  @Get('healthz')
  getHealthz() {
    return { status: 'ok' };
  }
}
