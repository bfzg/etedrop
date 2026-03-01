import { WebSocket } from 'ws';

export interface DeviceState {
  deviceId: string;
  deviceName: string;
  lastSeenAt: number;
  ws: WebSocket;
}

export interface SignalingSession {
  code: string;
  sender?: WebSocket;
  receiver?: WebSocket;
  createdAt: number;
}

export interface SocketSessionState {
  role: 'sender' | 'receiver';
  code: string;
}

export interface RuntimeStats {
  onlineDevices: number;
  waitingSessions: number;
  pairedSessions: number;
}
