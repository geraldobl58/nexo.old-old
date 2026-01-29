import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { MetricsController } from './metrics.controller';
import { MetricsService } from './metrics.service';

@Module({
  imports: [],
  controllers: [HealthController, MetricsController],
  providers: [MetricsService],
})
export class AppModule {}
