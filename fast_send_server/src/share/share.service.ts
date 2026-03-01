import { Injectable } from '@nestjs/common';
import { createHash, randomBytes } from 'node:crypto';

import {
  ShareInfo,
  ShareRecord,
} from '../common/interfaces/share-record.interface';
import { CreateShareDto } from './dto/create-share.dto';

@Injectable()
export class ShareService {
  private readonly shares = new Map<string, ShareRecord>();

  createShare(dto: CreateShareDto): ShareInfo {
    const now = Date.now();
    const code = this.generateCode();
    const record: ShareRecord = {
      code,
      path: dto.path,
      fileName: dto.fileName,
      size: dto.size,
      passwordHash: dto.password ? this.hashPassword(dto.password) : undefined,
      createdAt: now,
      expiresAt: dto.expiresIn ? now + dto.expiresIn : undefined,
    };

    this.shares.set(code, record);
    return this.toShareInfo(record);
  }

  listShares(): ShareInfo[] {
    this.cleanupExpired();
    return [...this.shares.values()]
      .sort((a, b) => b.createdAt - a.createdAt)
      .map((record) => this.toShareInfo(record));
  }

  getShare(code: string, password?: string): ShareInfo | null {
    const normalizedCode = code.trim().toUpperCase();
    const record = this.shares.get(normalizedCode);
    if (!record) {
      return null;
    }

    if (record.expiresAt && Date.now() > record.expiresAt) {
      this.shares.delete(normalizedCode);
      return null;
    }

    if (record.passwordHash) {
      if (!password || this.hashPassword(password) !== record.passwordHash) {
        return null;
      }
    }

    return this.toShareInfo(record);
  }

  deleteShare(code: string): boolean {
    return this.shares.delete(code.trim().toUpperCase());
  }

  private cleanupExpired(): void {
    const now = Date.now();
    for (const [code, record] of this.shares.entries()) {
      if (record.expiresAt && now > record.expiresAt) {
        this.shares.delete(code);
      }
    }
  }

  private generateCode(): string {
    let code = '';
    do {
      code = randomBytes(4).toString('hex').toUpperCase();
    } while (this.shares.has(code));
    return code;
  }

  private hashPassword(password: string): string {
    return createHash('sha256').update(password).digest('hex');
  }

  private toShareInfo(record: ShareRecord): ShareInfo {
    return {
      code: record.code,
      path: record.path,
      fileName: record.fileName,
      size: record.size,
      hasPassword: Boolean(record.passwordHash),
      createdAt: record.createdAt,
      expiresAt: record.expiresAt,
    };
  }
}
