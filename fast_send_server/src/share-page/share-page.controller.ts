import { join } from 'node:path';

import { Controller, Get, Logger, Next, Param, Res } from '@nestjs/common';
import type { NextFunction, Response } from 'express';

/**
 * 分享页 SPA 入口，由 share-page-app 构建到 public/share/。
 * 默认：相对编译产物 `dist/share-page/`，`..` / `..` 回到项目根再进 `public/share/`（与
 * ServeStatic 的 public 根一致，**不**使用 process.cwd()）。
 * 也可设环境变量 `FAST_SEND_PUBLIC_ROOT=/绝对路径/到/项目根/public` 强制指定 public 目录（整目录
 * 即 Nginx/静态资源根，内含 share/index.html），便于热修未重新 build 的旧部署包。
 */
function resolveShareIndexPath(): string {
  const fromEnv = process.env.FAST_SEND_PUBLIC_ROOT?.trim();
  if (fromEnv) {
    return join(fromEnv, 'share', 'index.html');
  }
  return join(__dirname, '..', '..', 'public', 'share', 'index.html');
}

const SHARE_INDEX_PATH = resolveShareIndexPath();

/**
 * 分享页：/share/:deviceId/:shareCode 返回 SPA；/share/assets/*、/share/svg/* 放行给静态中间件，
 * 否则会被误匹配导致返回 HTML（JS/CSS/SVG 需正确 MIME）。
 */
const STATIC_SEGMENTS = new Set(['assets', 'svg', 'img']);

@Controller('share')
export class SharePageController {
  private readonly logger = new Logger(SharePageController.name);

  constructor() {
    this.logger.log(`Share SPA: ${SHARE_INDEX_PATH}`);
  }

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
