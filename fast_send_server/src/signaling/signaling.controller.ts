import { Controller, Get } from '@nestjs/common';

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
      timestamp: Date.now(),
    };
  }
}
