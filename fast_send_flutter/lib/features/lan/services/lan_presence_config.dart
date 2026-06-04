/// 局域网发现与在线状态阈值（与 [LanDiscoveryService] 心跳周期联动）。
abstract final class LanPresenceConfig {
  LanPresenceConfig._();

  static const int udpPort = 53317;
  static const String multicastGroupIpv4 = '239.255.88.117';

  /// 周期宣告间隔。
  static const Duration heartbeatInterval = Duration(seconds: 8);

  /// 网卡指纹轮询（无变化则不重绑 socket）。
  static const Duration networkPollInterval = Duration(seconds: 20);

  /// 超过该时间未收到宣告 → UI 弱信号（仍视为可尝试连接）。
  static const int weakMs = 16000;

  /// 超过该时间仍无宣告 → 离线（保留在列表）。
  static const int offlineMs = 48000;

  /// 在线设备多久未更新后开始单播 probe（带退避）。
  static const int probeMinAgeMs = 6000;

  /// 已标离线但仍在短时内对其 IP 探测（启动拉活记住的设备）。
  static const int probeOfflineGraceMs = 120000;

  /// 列表条目遗忘时间。
  static const int forgetMs = 14 * 24 * 60 * 60 * 1000;

  /// 上线 / 重绑后的 presence burst 次数。
  static const int presenceBurstCount = 6;

  /// 每 N 次心跳附带一次 255.255.255.255。
  static const int fullBroadcastEveryNHeartbeats = 6;

  /// 启动后 macOS 本地网络权限：强制重绑轮数（间隔 3s）。
  static const int macosStartupRebindRounds = 4;

  static const Duration macosStartupRebindInterval = Duration(seconds: 3);

  /// 启动时对记住设备单播 probe 的轮次（间隔见 [startupProbeDelaysMs]）。
  static const List<int> startupProbeDelaysMs = [0, 350, 900];
}
