import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

@ApiTags('Health')
@Controller()
export class HealthController {
  @Get('health')
  @ApiOperation({
    summary: 'Deploy funcionando show de bola - Version 2 🚀',
  })
  @ApiResponse({
    status: 200,
    description: 'Deploy funcionando show de bola - Version 2 🚀',
    schema: {
      type: 'object',
      properties: {
        status: { type: 'string', example: 'ok' },
        timestamp: { type: 'string', example: '2026-01-21T12:00:00.000Z' },
        uptime: { type: 'number', example: 123.456 },
      },
    },
  })
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }
}
