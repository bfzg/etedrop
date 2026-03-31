import { join } from 'node:path';

import { Controller, Get, Next, Param, Res } from '@nestjs/common';
import type { NextFunction, Response } from 'express';

/** 分享页 SPA 入口，由 share-page-app 构建到 public/share/ */
const SHARE_INDEX_PATH = join(process.cwd(), 'public', 'share', 'index.html');

/**
 * 分享页：/share/:deviceId/:shareCode 返回 SPA；/share/assets/*、/share/svg/* 放行给静态中间件，
 * 否则会被误匹配导致返回 HTML（JS/CSS/SVG 需正确 MIME）。
 */
const STATIC_SEGMENTS = new Set(['assets', 'svg', 'img']);

@Controller('share')
export class SharePageController {
  @Get(':deviceId/:shareCode')
  getSharePage(
    @Param('deviceId') deviceId: string,
    @Param('shareCode') _shareCode: string,
    @Res() res: Response,
    @Next() next: NextFunction,
  ): void {
    if (STATIC_SEGMENTS.has(deviceId)) {
      next();
      return;
    }
    res.sendFile(SHARE_INDEX_PATH);
  }
}
