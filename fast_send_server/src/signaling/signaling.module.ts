import { Module } from '@nestjs/common';

import { SignalingController } from './signaling.controller';
import { SignalingService } from './signaling.service';
import { UsageAnalyticsService } from './usage-analytics.service';

@Module({
  controllers: [SignalingController],
  providers: [SignalingService, UsageAnalyticsService],
  exports: [SignalingService],
})
export class SignalingModule {}
