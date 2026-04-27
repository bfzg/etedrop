import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { mkdir, appendFile, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';

import { RuntimeStats } from '../common/interfaces/signaling-state.interface';
import {
  DeviceRegistryRecord,
  DeviceUsageEvent,
  UsageSummary,
} from '../common/interfaces/usage-analytics.interface';

const ONE_DAY_MS = 24 * 60 * 60 * 1000;
const DEFAULT_RECENT_EVENTS_LIMIT = 200;

@Injectable()
export class UsageAnalyticsService implements OnModuleInit {
  private readonly logger = new Logger(UsageAnalyticsService.name);
  // 与项目根目录下 runtime/ 一致，不依赖 process.cwd()（见 share-page.controller）
  private readonly runtimeDir = join(__dirname, '..', '..', 'runtime');
  private readonly registryFilePath = join(
    this.runtimeDir,
    'device-registry.json',
  );
  private readonly eventLogPath = join(this.runtimeDir, 'device-usage.log');

  private readonly registry = new Map<string, DeviceRegistryRecord>();
  private readonly recentEvents: DeviceUsageEvent[] = [];
  private ioQueue: Promise<void> = Promise.resolve();

  async onModuleInit(): Promise<void> {
    await this.ensureStorageReady();
  }

  recordDeviceOnline(
    deviceId: string,
    deviceName: string,
  ): { isFirstSeen: boolean } {
    const now = Date.now();
    const normalizedName = deviceName.trim() || 'unknown-device';
    const existing = this.registry.get(deviceId);
    const isFirstSeen = !existing;
    const record: DeviceRegistryRecord = existing
      ? {
          ...existing,
          lastSeenAt: now,
          lastOnlineAt: now,
          lastDeviceName: normalizedName,
          totalOnlineCount: existing.totalOnlineCount + 1,
        }
      : {
          deviceId,
          firstSeenAt: now,
          lastSeenAt: now,
          lastDeviceName: normalizedName,
          totalOnlineCount: 1,
          browserConnectCount: 0,
          lastOnlineAt: now,
        };

    this.registry.set(deviceId, record);
    this.persistRegistry();
    this.pushEvent({
      timestamp: now,
      event: 'device_online',
      deviceId,
      deviceName: normalizedName,
    });
    return { isFirstSeen };
  }

  recordDeviceOffline(deviceId: string, reason: string): void {
    const now = Date.now();
    const record = this.registry.get(deviceId);
    if (record) {
      record.lastSeenAt = now;
      record.lastOfflineAt = now;
      this.registry.set(deviceId, record);
      this.persistRegistry();
    }

    this.pushEvent({
      timestamp: now,
      event: 'device_offline',
      deviceId,
      reason,
    });
  }

  recordBrowserConnect(deviceId: string, peerId: string): void {
    const now = Date.now();
    const record = this.registry.get(deviceId);
    if (record) {
      record.browserConnectCount += 1;
      record.lastSeenAt = now;
      this.registry.set(deviceId, record);
      this.persistRegistry();
    }

    this.pushEvent({
      timestamp: now,
      event: 'browser_connect',
      deviceId,
      peerId,
    });
  }

  touchDeviceHeartbeat(deviceId: string): void {
    const record = this.registry.get(deviceId);
    if (!record) {
      return;
    }
    record.lastSeenAt = Date.now();
    this.registry.set(deviceId, record);
  }

  getUsageSummary(onlineDeviceIds: string[]): UsageSummary {
    const now = Date.now();
    let activeDevices24h = 0;
    let totalOnlineEvents = 0;
    let totalBrowserConnectEvents = 0;
    for (const record of this.registry.values()) {
      if (now - record.lastSeenAt <= ONE_DAY_MS) {
        activeDevices24h += 1;
      }
      totalOnlineEvents += record.totalOnlineCount;
      totalBrowserConnectEvents += record.browserConnectCount;
    }

    return {
      installedDevices: this.registry.size,
      onlineDevices: onlineDeviceIds.length,
      activeDevices24h,
      totalOnlineEvents,
      totalBrowserConnectEvents,
      recordedAt: now,
    };
  }

  getKnownDevices(
    onlineDeviceIds: string[],
    limit = 200,
  ): Array<DeviceRegistryRecord & { isOnline: boolean }> {
    const onlineSet = new Set(onlineDeviceIds);
    return [...this.registry.values()]
      .sort((a, b) => b.lastSeenAt - a.lastSeenAt)
      .slice(0, Math.max(1, limit))
      .map((record) => ({
        ...record,
        isOnline: onlineSet.has(record.deviceId),
      }));
  }

  getRecentEvents(limit = DEFAULT_RECENT_EVENTS_LIMIT): DeviceUsageEvent[] {
    const max = Math.max(1, limit);
    return this.recentEvents.slice(-max).reverse();
  }

  renderPrometheusMetrics(
    runtimeStats: RuntimeStats,
    summary: UsageSummary,
  ): string {
    return [
      '# HELP fast_send_online_devices Current online device count.',
      '# TYPE fast_send_online_devices gauge',
      `fast_send_online_devices ${runtimeStats.onlineDevices}`,
      '# HELP fast_send_waiting_sessions Current waiting signaling sessions.',
      '# TYPE fast_send_waiting_sessions gauge',
      `fast_send_waiting_sessions ${runtimeStats.waitingSessions}`,
      '# HELP fast_send_paired_sessions Current paired signaling sessions.',
      '# TYPE fast_send_paired_sessions gauge',
      `fast_send_paired_sessions ${runtimeStats.pairedSessions}`,
      '# HELP fast_send_installed_devices Total unique devices seen by server.',
      '# TYPE fast_send_installed_devices gauge',
      `fast_send_installed_devices ${summary.installedDevices}`,
      '# HELP fast_send_active_devices_24h Unique active devices in last 24h.',
      '# TYPE fast_send_active_devices_24h gauge',
      `fast_send_active_devices_24h ${summary.activeDevices24h}`,
      '# HELP fast_send_device_online_events_total Historical device-online events.',
      '# TYPE fast_send_device_online_events_total counter',
      `fast_send_device_online_events_total ${summary.totalOnlineEvents}`,
      '# HELP fast_send_browser_connect_events_total Historical browser-connect events.',
      '# TYPE fast_send_browser_connect_events_total counter',
      `fast_send_browser_connect_events_total ${summary.totalBrowserConnectEvents}`,
    ].join('\n');
  }

  private async ensureStorageReady(): Promise<void> {
    try {
      await mkdir(this.runtimeDir, { recursive: true });
      const file = await readFile(this.registryFilePath, 'utf8');
      const parsed = JSON.parse(file) as DeviceRegistryRecord[];
      if (!Array.isArray(parsed)) {
        return;
      }
      for (const item of parsed) {
        if (!item?.deviceId) {
          continue;
        }
        this.registry.set(item.deviceId, item);
      }
      this.logger.log(`Loaded device registry: ${this.registry.size} devices`);
    } catch {
      // First boot or invalid registry file should not block the service.
    }
  }

  private pushEvent(event: DeviceUsageEvent): void {
    this.recentEvents.push(event);
    if (this.recentEvents.length > DEFAULT_RECENT_EVENTS_LIMIT) {
      this.recentEvents.shift();
    }
    this.enqueueIo(async () => {
      await appendFile(this.eventLogPath, `${JSON.stringify(event)}\n`, 'utf8');
    });
  }

  private persistRegistry(): void {
    const payload = JSON.stringify([...this.registry.values()], null, 2);
    this.enqueueIo(async () => {
      await writeFile(this.registryFilePath, payload, 'utf8');
    });
  }

  private enqueueIo(task: () => Promise<void>): void {
    this.ioQueue = this.ioQueue
      .then(task)
      .catch((err) =>
        this.logger.warn(`Usage analytics I/O failed: ${String(err)}`),
      );
  }
}
