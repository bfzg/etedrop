export interface ShareFileItem {
  name: string;
  size: number;
  isDirectory?: boolean;
  modifiedAt?: number;
}

export interface ShareCheckRequestMessage {
  peerId: string;
  shareCode?: string;
}

export interface ShareCheckResultMessage {
  ok: boolean;
  needShareCode: boolean;
  files?: ShareFileItem[];
  errorCode?: string;
  errorMessage?: string;
}

export interface ShareCheckResponseMessage extends ShareCheckResultMessage {
  peerId: string;
}
