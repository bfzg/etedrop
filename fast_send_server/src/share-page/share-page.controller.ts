import { Controller, Get, Header, Param } from '@nestjs/common';

import { SharePageService } from './share-page.service';

@Controller('share')
export class SharePageController {
  constructor(private readonly sharePageService: SharePageService) {}

  @Get(':deviceId/:shareCode')
  @Header('Content-Type', 'text/html; charset=utf-8')
  getSharePage(
    @Param('deviceId') deviceId: string,
    @Param('shareCode') shareCode: string,
  ): string {
    return this.sharePageService.renderSharePage(deviceId, shareCode);
  }
}
