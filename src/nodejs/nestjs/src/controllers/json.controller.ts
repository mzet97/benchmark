import { Controller, Get } from '@nestjs/common';

@Controller('json')
export class JsonController {
  @Get()
  getJson() {
    const items = Array.from({ length: 1000 }, (_, i) => ({
      id: i + 1,
      name: 'Item ' + (i + 1),
      value: 'Value ' + (i + 1),
      timestamp: new Date().toISOString(),
    }));

    return {
      items,
      count: items.length,
    };
  }
}
