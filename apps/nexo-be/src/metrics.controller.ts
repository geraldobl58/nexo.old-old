import { Controller, Get, Header } from '@nestjs/common';
import { ApiResponse, ApiTags } from '@nestjs/swagger';
import { MetricsService } from './metrics.service';

@ApiTags('Metrics')
@Controller()
export class MetricsController {
  constructor(private readonly metricsService: MetricsService) {}

  @Get('metrics')
  @Header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
  @ApiResponse({
    status: 200,
    description: 'Prometheus metrics',
    content: {
      'text/plain': {
        schema: {
          type: 'string',
          example:
            '# HELP http_requests_total The total number of HTTP requests.\n# TYPE http_requests_total counter\nhttp_requests_total{method="get",code="200"} 1027\nhttp_requests_total{method="post",code="400"} 3\n',
        },
      },
    },
  })
  async getMetrics() {
    return this.metricsService.getMetrics();
  }
}
