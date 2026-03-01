export interface ShareRecord {
  code: string;
  path: string;
  fileName: string;
  size: number;
  passwordHash?: string;
  createdAt: number;
  expiresAt?: number;
}

export interface ShareInfo {
  code: string;
  path: string;
  fileName: string;
  size: number;
  hasPassword: boolean;
  createdAt: number;
  expiresAt?: number;
}
