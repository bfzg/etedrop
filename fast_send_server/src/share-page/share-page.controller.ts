import { join } from 'node:path';

import { Controller, Get, Param, Res } from '@nestjs/common';
import type { Response } from 'express';

/**
 * 分享页使用 React 构建产物（share-page-app build 到 public/share/）。
 * 任意 /share/:deviceId/:shareCode 均返回 SPA 的 index.html，由前端路由解析参数。
 */
@Controller('share')
export class SharePageController {
  @Get(':deviceId/:shareCode')
  getSharePage(
    @Param('deviceId') _deviceId: string,
    @Param('shareCode') _shareCode: string,
    @Res() res: Response,
  ): void {
    const path = join(process.cwd(), 'public', 'share', 'index.html');
    res.sendFile(path);
  }
}
