import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { Injectable } from '@nestjs/common';

const TEMPLATE_PLACEHOLDERS = {
  DEVICE_ID: '{{DEVICE_ID}}',
  SHARE_CODE: '{{SHARE_CODE}}',
} as const;

@Injectable()
export class SharePageService {
  private template: string | null = null;

  private getTemplate(): string {
    if (this.template !== null) return this.template;
    const path = join(__dirname, 'templates', 'share-page.html');
    this.template = readFileSync(path, 'utf-8');
    return this.template;
  }

  renderSharePage(deviceId: string, shareCode: string): string {
    const escapedDeviceId = this.escapeHtml(deviceId);
    const escapedShareCode = this.escapeHtml(shareCode);
    const html = this.getTemplate();
    return html
      .replaceAll(TEMPLATE_PLACEHOLDERS.DEVICE_ID, escapedDeviceId)
      .replaceAll(TEMPLATE_PLACEHOLDERS.SHARE_CODE, escapedShareCode);
  }

  private escapeHtml(s: string): string {
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
    };
    return s.replace(/[&<>"']/g, (ch) => map[ch] ?? ch);
  }
}
