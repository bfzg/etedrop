import { Controller, Get, Header, Query } from '@nestjs/common';

import { SignalingService } from './signaling.service';

@Controller('api/system')
export class SignalingController {
  constructor(private readonly signalingService: SignalingService) {}

  @Get('health')
  health() {
    return {
      ok: true,
      service: 'fast_send_server',
      signaling: this.signalingService.getRuntimeStats(),
      usage: this.signalingService.getUsageSummary(),
      timestamp: Date.now(),
    };
  }

  @Get('usage/summary')
  usageSummary() {
    return this.signalingService.getUsageSummary();
  }

  @Get('usage/devices')
  usageDevices(@Query('limit') limit?: string) {
    const parsed = Number(limit);
    const safeLimit = Number.isFinite(parsed)
      ? Math.min(Math.max(parsed, 1), 2000)
      : 200;
    return {
      devices: this.signalingService.getKnownDevices(safeLimit),
      count: safeLimit,
      timestamp: Date.now(),
    };
  }

  @Get('usage/events')
  usageEvents(@Query('limit') limit?: string) {
    const parsed = Number(limit);
    const safeLimit = Number.isFinite(parsed)
      ? Math.min(Math.max(parsed, 1), 1000)
      : 200;
    return {
      events: this.signalingService.getRecentUsageEvents(safeLimit),
      count: safeLimit,
      timestamp: Date.now(),
    };
  }

  @Get('metrics')
  @Header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
  metrics() {
    return this.signalingService.getPrometheusMetrics();
  }
}
