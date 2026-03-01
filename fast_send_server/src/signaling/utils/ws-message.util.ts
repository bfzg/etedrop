import { RawData, WebSocket } from 'ws';

import { WsMessage } from '../../common/interfaces/ws-message.interface';

export function parseWsMessage(raw: unknown): WsMessage | null {
  try {
    const text = rawDataToText(raw);
    if (!text) {
      return null;
    }

    const parsed: unknown = JSON.parse(text);
    return isWsMessage(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

export function sendWsMessage(ws: unknown, message: WsMessage): void {
  if (!(ws instanceof WebSocket) || ws.readyState !== WebSocket.OPEN) {
    return;
  }

  ws.send(JSON.stringify(message));
}

function rawDataToText(raw: unknown): string {
  if (!isRawData(raw)) {
    return '';
  }

  if (typeof raw === 'string') {
    return raw;
  }

  if (Buffer.isBuffer(raw)) {
    return raw.toString();
  }

  if (Array.isArray(raw)) {
    return Buffer.concat(raw).toString();
  }

  if (raw instanceof ArrayBuffer) {
    return Buffer.from(new Uint8Array(raw)).toString();
  }

  return '';
}

function isRawData(value: unknown): value is RawData {
  if (typeof value === 'string') {
    return true;
  }

  if (Buffer.isBuffer(value)) {
    return true;
  }

  if (value instanceof ArrayBuffer) {
    return true;
  }

  return Array.isArray(value) && value.every((item) => Buffer.isBuffer(item));
}

function isWsMessage(value: unknown): value is WsMessage {
  if (!value || typeof value !== 'object') {
    return false;
  }

  return typeof (value as WsMessage).type === 'string';
}
