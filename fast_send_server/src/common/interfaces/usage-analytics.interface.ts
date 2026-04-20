export type DeviceUsageEventType =
  | 'device_online'
  | 'device_offline'
  | 'browser_connect';

export interface DeviceUsageEvent {
  timestamp: number;
  event: DeviceUsageEventType;
  deviceId: string;
  deviceName?: string;
  peerId?: string;
  reason?: string;
}

export interface DeviceRegistryRecord {
  deviceId: string;
  firstSeenAt: number;
  lastSeenAt: number;
  lastDeviceName: string;
  totalOnlineCount: number;
  browserConnectCount: number;
  lastOnlineAt?: number;
  lastOfflineAt?: number;
}

export interface UsageSummary {
  installedDevices: number;
  onlineDevices: number;
  activeDevices24h: number;
  totalOnlineEvents: number;
  totalBrowserConnectEvents: number;
  recordedAt: number;
}
