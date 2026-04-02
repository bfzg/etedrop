import {
  Inject,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { randomBytes, randomUUID } from 'node:crypto';
import { Server as HttpServer } from 'node:http';
import { WebSocket, WebSocketServer } from 'ws';

import {
  DeviceState,
  RuntimeStats,
  SignalingSession,
  SocketSessionState,
} from '../common/interfaces/signaling-state.interface';
import { WsMessage } from '../common/interfaces/ws-message.interface';
import {
  DEVICE_INACTIVE_TIMEOUT_MS,
  SESSION_TIMEOUT_MS,
  SIGNALING_CONNECT_PATH,
  SIGNALING_HEARTBEAT_INTERVAL_MS,
  SIGNALING_SHARE_PATH,
} from './constants/signaling-paths';
import { parseWsMessage, sendWsMessage } from './utils/ws-message.util';
import {
  attachWsUpgradeHandler,
  closeWsServer,
  createWsServer,
} from './utils/ws-upgrade.util';

@Injectable()
export class SignalingService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(SignalingService.name);

  private connectWss?: WebSocketServer;
  private shareWss?: WebSocketServer;

  private readonly sessions = new Map<string, SignalingSession>();
  private readonly socketSessions = new Map<WebSocket, SocketSessionState>();

  private readonly devices = new Map<string, DeviceState>();
  private readonly socketDeviceId = new Map<WebSocket, string>();

  /** 浏览器连接 → 要连接的设备 ID */
  private readonly browserToDevice = new Map<WebSocket, string>();
  /** 浏览器连接 → 该次访问的 P2P 会话 ID（多浏览器并发互不抢占） */
  private readonly browserToPeerId = new Map<WebSocket, string>();
  /** 设备 ID → (peerId → 浏览器 WebSocket) */
  private readonly devicePeerBrowsers = new Map<string, Map<string, WebSocket>>();

  private heartbeatTimer?: NodeJS.Timeout;

  constructor(
    @Inject(HttpAdapterHost)
    private readonly httpAdapterHost: HttpAdapterHost,
  ) {}

  onModuleInit(): void {
    const httpServer =
      this.httpAdapterHost.httpAdapter.getHttpServer() as HttpServer;

    this.connectWss = createWsServer((ws) => this.handleConnectSocket(ws));
    this.shareWss = createWsServer((ws) => this.handleShareSocket(ws));

    attachWsUpgradeHandler(httpServer, [
      {
        path: SIGNALING_CONNECT_PATH,
        server: this.connectWss,
      },
      {
        path: SIGNALING_SHARE_PATH,
        server: this.shareWss,
      },
    ]);

    this.heartbeatTimer = setInterval(() => {
      this.broadcastSharePing();
      this.cleanupInactiveDevices();
      this.cleanupStaleSessions();
    }, SIGNALING_HEARTBEAT_INTERVAL_MS);

    this.logger.log(
      `WebSocket endpoints ready: ${SIGNALING_CONNECT_PATH}, ${SIGNALING_SHARE_PATH}`,
    );
  }

  onModuleDestroy(): void {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = undefined;
    }

    closeWsServer(this.connectWss);
    closeWsServer(this.shareWss);

    this.sessions.clear();
    this.socketSessions.clear();
    this.devices.clear();
    this.socketDeviceId.clear();
    this.browserToDevice.clear();
    this.browserToPeerId.clear();
    this.devicePeerBrowsers.clear();
  }

  getRuntimeStats(): RuntimeStats {
    let pairedSessions = 0;
    let waitingSessions = 0;

    for (const session of this.sessions.values()) {
      if (session.sender && session.receiver) {
        pairedSessions += 1;
      } else {
        waitingSessions += 1;
      }
    }

    return {
      onlineDevices: this.devices.size,
      waitingSessions,
      pairedSessions,
    };
  }

  private handleConnectSocket(ws: WebSocket): void {
    ws.on('message', (raw) => {
      const message = parseWsMessage(raw);
      if (!message) {
        this.sendSafe(ws, {
          type: 'err',
          code: 'BAD_FORMAT',
          msg: '消息格式错误',
        });
        return;
      }

      this.handleConnectMessage(ws, message);
    });

    ws.on('close', () => {
      this.cleanupConnectSocket(ws);
    });

    ws.on('error', () => {
      this.cleanupConnectSocket(ws);
    });
  }

  private handleConnectMessage(ws: WebSocket, message: WsMessage): void {
    switch (message.type) {
      case 'send':
        this.registerSender(ws);
        break;
      case 'receive': {
        const code = this.normalizeCode(message.code);
        if (!code) {
          this.sendSafe(ws, { type: 'status', code: 404 });
          return;
        }
        this.registerReceiver(ws, code);
        break;
      }
      case 'sdp':
      case 'candidate':
        this.forwardSignalingPayload(ws, message);
        break;
      case 'ping':
      case 'heartbeat':
        this.sendSafe(ws, { type: 'ping' });
        break;
      default:
        this.sendSafe(ws, {
          type: 'err',
          code: 'UNKNOWN_TYPE',
          msg: `不支持的消息类型: ${message.type}`,
        });
    }
  }

  private registerSender(ws: WebSocket): void {
    this.cleanupConnectSocket(ws);

    const code = this.generateCode();
    const session: SignalingSession = {
      code,
      sender: ws,
      createdAt: Date.now(),
    };

    this.sessions.set(code, session);
    this.socketSessions.set(ws, { role: 'sender', code });

    this.sendSafe(ws, { type: 'code', code });
  }

  private registerReceiver(ws: WebSocket, code: string): void {
    this.cleanupConnectSocket(ws);

    const session = this.sessions.get(code);
    if (!session || !session.sender) {
      this.sendSafe(ws, { type: 'status', code: 404 });
      return;
    }

    if (session.receiver && session.receiver !== ws) {
      this.sendSafe(ws, {
        type: 'err',
        code: 'CODE_IN_USE',
        msg: '该取件码已被使用',
      });
      return;
    }

    session.receiver = ws;
    this.socketSessions.set(ws, { role: 'receiver', code });

    this.sendSafe(ws, { type: 'status', code: 0 });
    this.sendSafe(session.sender, { type: 'peer-connect', code });
  }

  private forwardSignalingPayload(source: WebSocket, message: WsMessage): void {
    const state = this.socketSessions.get(source);
    if (!state) {
      this.sendSafe(source, {
        type: 'err',
        code: 'SESSION_INVALID',
        msg: '会话未初始化',
      });
      return;
    }

    const session = this.sessions.get(state.code);
    if (!session) {
      this.sendSafe(source, {
        type: 'err',
        code: 'SESSION_NOT_FOUND',
        msg: '会话不存在',
      });
      return;
    }

    const target = state.role === 'sender' ? session.receiver : session.sender;

    if (!target) {
      this.sendSafe(source, {
        type: 'err',
        code: 'PEER_NOT_READY',
        msg: '对端未连接',
      });
      return;
    }

    this.sendSafe(target, {
      type: message.type,
      data: message.data,
    });
  }

  private cleanupConnectSocket(ws: WebSocket): void {
    const state = this.socketSessions.get(ws);
    if (!state) {
      return;
    }

    this.socketSessions.delete(ws);

    const session = this.sessions.get(state.code);
    if (!session) {
      return;
    }

    if (state.role === 'sender' && session.sender === ws) {
      session.sender = undefined;
      this.sendSafe(session.receiver, {
        type: 'err',
        code: 'PEER_DISCONNECTED',
        msg: '发送方已断开连接',
      });
    }

    if (state.role === 'receiver' && session.receiver === ws) {
      session.receiver = undefined;
      this.sendSafe(session.sender, {
        type: 'err',
        code: 'PEER_DISCONNECTED',
        msg: '接收方已断开连接',
      });
    }

    if (!session.sender && !session.receiver) {
      this.sessions.delete(state.code);
    }
  }

  private handleShareSocket(ws: WebSocket): void {
    ws.on('message', (raw) => {
      const message = parseWsMessage(raw);
      if (!message) {
        this.sendSafe(ws, {
          type: 'err',
          code: 'BAD_FORMAT',
          msg: '消息格式错误',
        });
        return;
      }

      this.handleShareMessage(ws, message);
    });

    ws.on('close', () => {
      this.cleanupShareSocket(ws);
    });

    ws.on('error', () => {
      this.cleanupShareSocket(ws);
    });
  }

  private handleShareMessage(ws: WebSocket, message: WsMessage): void {
    switch (message.type) {
      case 'device-online':
        this.registerDevice(ws, message);
        break;
      case 'connect':
        this.registerBrowser(ws, message);
        break;
      case 'heartbeat':
      case 'ping':
        this.handleSharePingOrHeartbeat(ws);
        break;
      case 'offer':
      case 'answer':
      case 'ice-candidate':
        this.forwardShareSignaling(ws, message);
        break;
      case 'peer-connect':
        this.forwardPeerConnect(message);
        break;
      default:
        this.sendSafe(ws, {
          type: 'err',
          code: 'UNKNOWN_TYPE',
          msg: `不支持的消息类型: ${message.type}`,
        });
    }
  }

  /**
   * 浏览器首条消息 connect + deviceId：查设备是否在线，回复 device-online 或 err(OFFLINE)，并建立浏览器↔设备配对
   */
  private registerBrowser(ws: WebSocket, message: WsMessage): void {
    const deviceId =
      typeof message.deviceId === 'string' ? message.deviceId.trim() : '';
    if (!deviceId) {
      this.sendSafe(ws, {
        type: 'err',
        code: 'INVALID',
        msg: 'deviceId 不能为空',
      });
      return;
    }

    const device = this.devices.get(deviceId);
    if (!device) {
      this.sendSafe(ws, {
        type: 'err',
        code: 'OFFLINE',
        msg: '分享者设备离线',
      });
      return;
    }

    const peerId = randomUUID();
    this.browserToDevice.set(ws, deviceId);
    this.browserToPeerId.set(ws, peerId);

    let peers = this.devicePeerBrowsers.get(deviceId);
    if (!peers) {
      peers = new Map<string, WebSocket>();
      this.devicePeerBrowsers.set(deviceId, peers);
    }
    peers.set(peerId, ws);

    this.sendSafe(ws, { type: 'device-online', deviceId, peerId });
    this.logger.log(`Browser connected to device ${deviceId} peer=${peerId}`);
  }

  /** 心跳/ ping：仅设备更新 lastSeen；浏览器回 ping；未识别连接提示先发 device-online 或 connect */
  private handleSharePingOrHeartbeat(ws: WebSocket): void {
    if (this.socketDeviceId.has(ws)) {
      this.updateDeviceHeartbeat(ws);
      return;
    }
    if (this.browserToPeerId.has(ws)) {
      this.sendSafe(ws, { type: 'ping' });
      return;
    }
    this.sendSafe(ws, {
      type: 'err',
      code: 'AUTH_REQUIRED',
      msg: '请先发送 device-online 或 connect',
    });
  }

  /**
   * 在「浏览器 ↔ 设备」之间双向转发 offer / answer / ice-candidate（与现有 peer-connect 兼容）
   */
  private forwardShareSignaling(source: WebSocket, message: WsMessage): void {
    const deviceIdFromSocket = this.socketDeviceId.get(source);
    const deviceIdFromBrowser = this.browserToDevice.get(source);

    if (deviceIdFromBrowser !== undefined) {
      const peerId = this.browserToPeerId.get(source);
      if (!peerId) {
        this.sendSafe(source, {
          type: 'err',
          code: 'AUTH_REQUIRED',
          msg: '会话未就绪',
        });
        return;
      }
      const device = this.devices.get(deviceIdFromBrowser);
      if (!device) {
        this.logger.warn(`Forward failed: device ${deviceIdFromBrowser} gone`);
        this.sendSafe(source, {
          type: 'err',
          code: 'OFFLINE',
          msg: '分享者设备已离线',
        });
        return;
      }
      this.sendSafe(device.ws, {
        type: message.type,
        data: message.data,
        peerId,
      });
      return;
    }

    if (deviceIdFromSocket !== undefined) {
      const peerId =
        typeof message.peerId === 'string' ? message.peerId.trim() : '';
      if (!peerId) {
        this.sendSafe(source, {
          type: 'err',
          code: 'MISSING_PEER',
          msg: '缺少 peerId，无法路由到浏览器',
        });
        return;
      }
      const peers = this.devicePeerBrowsers.get(deviceIdFromSocket);
      const browserWs = peers?.get(peerId);
      if (!browserWs) {
        this.sendSafe(source, {
          type: 'err',
          code: 'PEER_NOT_READY',
          msg: '对端浏览器会话已断开',
        });
        return;
      }
      this.sendSafe(browserWs, {
        type: message.type,
        data: message.data,
        peerId,
      });
      return;
    }

    this.sendSafe(source, {
      type: 'err',
      code: 'AUTH_REQUIRED',
      msg: '请先发送 device-online 或 connect',
    });
  }

  private registerDevice(ws: WebSocket, message: WsMessage): void {
    const deviceId =
      typeof message.deviceId === 'string' ? message.deviceId.trim() : '';
    const deviceName =
      typeof message.deviceName === 'string' ? message.deviceName.trim() : '';

    if (!deviceId) {
      this.sendSafe(ws, {
        type: 'err',
        code: 'INVALID',
        msg: 'deviceId 不能为空',
      });
      return;
    }

    const existed = this.devices.get(deviceId);
    if (existed && existed.ws !== ws) {
      this.socketDeviceId.delete(existed.ws);
      existed.ws.close();
    }

    this.devices.set(deviceId, {
      deviceId,
      deviceName: deviceName || 'unknown-device',
      lastSeenAt: Date.now(),
      ws,
    });
    this.socketDeviceId.set(ws, deviceId);

    this.sendSafe(ws, {
      type: 'device-online-ack',
      deviceId,
      serverTime: Date.now(),
    });
    this.logger.log(
      `Device online: ${deviceId} (${deviceName || 'unknown-device'})`,
    );
  }

  private updateDeviceHeartbeat(ws: WebSocket): void {
    const deviceId = this.socketDeviceId.get(ws);
    if (!deviceId) {
      this.sendSafe(ws, {
        type: 'err',
        code: 'NOT_REGISTERED',
        msg: '设备尚未注册',
      });
      return;
    }

    const device = this.devices.get(deviceId);
    if (!device) {
      return;
    }

    device.lastSeenAt = Date.now();
  }

  private forwardPeerConnect(message: WsMessage): void {
    const deviceId =
      typeof message.deviceId === 'string' ? message.deviceId.trim() : '';
    if (!deviceId) {
      return;
    }

    const target = this.devices.get(deviceId);
    if (!target) {
      return;
    }

    this.sendSafe(target.ws, {
      type: 'peer-connect',
      data: message.data,
    });
  }

  private cleanupShareSocket(ws: WebSocket): void {
    const deviceIdAsDevice = this.socketDeviceId.get(ws);
    if (deviceIdAsDevice !== undefined) {
      this.socketDeviceId.delete(ws);
      const state = this.devices.get(deviceIdAsDevice);
      if (state && state.ws === ws) {
        this.devices.delete(deviceIdAsDevice);
        this.logger.log(`Device offline: ${deviceIdAsDevice}`);
        const peers = this.devicePeerBrowsers.get(deviceIdAsDevice);
        if (peers) {
          for (const browserWs of peers.values()) {
            this.browserToDevice.delete(browserWs);
            this.browserToPeerId.delete(browserWs);
            this.sendSafe(browserWs, {
              type: 'err',
              code: 'OFFLINE',
              msg: '分享者设备已断开',
            });
          }
          this.devicePeerBrowsers.delete(deviceIdAsDevice);
        }
      }
      return;
    }

    const deviceIdAsBrowser = this.browserToDevice.get(ws);
    if (deviceIdAsBrowser !== undefined) {
      const peerId = this.browserToPeerId.get(ws);
      this.browserToDevice.delete(ws);
      this.browserToPeerId.delete(ws);
      if (peerId) {
        this.devicePeerBrowsers.get(deviceIdAsBrowser)?.delete(peerId);
      }
      const remaining = this.devicePeerBrowsers.get(deviceIdAsBrowser);
      if (remaining?.size === 0) {
        this.devicePeerBrowsers.delete(deviceIdAsBrowser);
      }
      this.logger.debug(
        `Browser disconnected from device ${deviceIdAsBrowser} peer=${peerId ?? '?'}`,
      );
    }
  }

  private broadcastSharePing(): void {
    for (const device of this.devices.values()) {
      this.sendSafe(device.ws, { type: 'ping' });
    }
  }

  private cleanupInactiveDevices(): void {
    const now = Date.now();

    for (const [deviceId, state] of this.devices.entries()) {
      if (now - state.lastSeenAt > DEVICE_INACTIVE_TIMEOUT_MS) {
        this.logger.log(`Device timeout: ${deviceId}`);
        const peers = this.devicePeerBrowsers.get(deviceId);
        if (peers) {
          for (const browserWs of peers.values()) {
            this.browserToDevice.delete(browserWs);
            this.browserToPeerId.delete(browserWs);
            this.sendSafe(browserWs, {
              type: 'err',
              code: 'OFFLINE',
              msg: '分享者设备已离线',
            });
          }
          this.devicePeerBrowsers.delete(deviceId);
        }
        this.devices.delete(deviceId);
        this.socketDeviceId.delete(state.ws);
        state.ws.close();
      }
    }
  }

  private cleanupStaleSessions(): void {
    const now = Date.now();

    for (const [code, session] of this.sessions.entries()) {
      if (now - session.createdAt > SESSION_TIMEOUT_MS) {
        this.sendSafe(session.sender, {
          type: 'err',
          code: 'SESSION_TIMEOUT',
          msg: '会话已超时',
        });
        this.sendSafe(session.receiver, {
          type: 'err',
          code: 'SESSION_TIMEOUT',
          msg: '会话已超时',
        });

        session.sender?.close();
        session.receiver?.close();

        this.sessions.delete(code);
      }
    }
  }

  private normalizeCode(value: unknown): string | null {
    if (typeof value !== 'string') {
      return null;
    }

    const code = value.trim().toUpperCase();
    return code ? code : null;
  }

  private generateCode(): string {
    let code = '';
    do {
      code = randomBytes(3).toString('hex').toUpperCase();
    } while (this.sessions.has(code));

    return code;
  }

  private sendSafe(ws: WebSocket | undefined, message: WsMessage): void {
    sendWsMessage(ws, message);
  }
}
