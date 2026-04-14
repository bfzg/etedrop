/// 全局常量配置
///
/// API / 分享 WS / 信令 WS 均由 [ServerEndpoints.resolve]（设置「服务器线路」）解析；
/// [DeviceManager] 首帧用 [resolveServerEndpointsSync] 与 [serverEndpointsProvider] 对齐。
/// WebRTC STUN 顺序由 [ServerEndpoints.mainlandStunPreferred] 与 [pubIceServersForRegion] 对齐。
///
/// 自建或调试后端：改 [ServerEndpoints] 里 `API_BASE_GLOBAL` / `API_BASE_MAINLAND` 的
/// `String.fromEnvironment` 默认值，或编译时传入 `--dart-define=API_BASE_GLOBAL=http://...`。
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = 'EteDrop';

  /// 应用版本号与构建：**只改 [pubspec.yaml] 顶部的 `version: x.y.z+build`** 即可；
  /// iOS / Android / macOS / Windows 构建与 [package_info_plus] 均从此读取。
  /// 不要在常量里再写一份版本，避免不一致。

  /// 更新清单（自建 HTTP）：返回 JSON
  static const String updateManifestUrl =
      'https://www.etedrop.com/public/version.json';
  // static const String updateManifestUrl =
  //     'http://192.168.1.9:3000/version.json';

  /// iOS 上架后配置（用于「去商店更新」跳转）
  static const String iosStoreUrl = '';

  /// Android 上架后配置应用商店地址；非空时 [UpdateService] 优先跳转此处。
  /// 留空则跳转 [androidUpdateDownloadPageUrl]（未上架前官网验证用）。
  static const String androidStoreUrl = '';

  /// 未上架前：安卓检查更新弹窗「更新」打开的官网下载页。
  static const String androidUpdateDownloadPageUrl = 'https://etedrop.com/down';

  /// WebRTC DataChannel 默认分块大小（分享下载分片负载，不含 8 字节偏移头）。
  /// 32KB→64KB 可减少帧数与 SCTP 开销，利于跨网吞吐；若个别环境单帧异常可再回调。
  static const int defaultBlockSize = 65536;

  /// WebRTC ICE：STUN 仅用于发现地址；顺序与 `share-page-app` 中 `pubIceServersForHost` 规则对齐。
  /// 公网列表参考 https://gist.github.com/mondain/b0ec1cf5f60ae726202e ；不宜塞入过多 URL。
  /// 复杂 NAT 需自建 TURN，仅靠 STUN 无法中继。
  static const List<String> _pubStunUrlsMainlandFirst = [
    'stun:stun.chat.bilibili.com:3478',
    'stun:stun.cloudflare.com:3478',
    'stun:stun.fbsbx.com:3478',
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
    'stun:stun3.l.google.com:19302',
    'stun:stun4.l.google.com:19302',
    'stun:stun.counterpath.net:3478',
    'stun:stun.stunprotocol.org:3478',
  ];

  /// 海外/全球线：Google 系优先，其次公网常用 STUN（含境内友好节点作兜底）。
  static const List<String> _pubStunUrlsGlobalFirst = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
    'stun:stun3.l.google.com:19302',
    'stun:stun4.l.google.com:19302',
    'stun:stun.cloudflare.com:3478',
    'stun:stun.fbsbx.com:3478',
    'stun:stun.chat.bilibili.com:3478',
    'stun:stun.counterpath.net:3478',
    'stun:stun.stunprotocol.org:3478',
  ];

  /// 与 [ServerEndpoints.mainlandStunPreferred] 一致：大陆 API 线时 [mainlandStunPreferred] 为 true。
  static List<Map<String, dynamic>> pubIceServersForRegion({
    required bool mainlandStunPreferred,
  }) {
    final urls =
        mainlandStunPreferred ? _pubStunUrlsMainlandFirst : _pubStunUrlsGlobalFirst;
    return [
      <String, dynamic>{'urls': List<String>.from(urls)},
    ];
  }

  /// 设备配置文件名
  static const String deviceConfigFileName = 'device-config.json';

  /// 分享记录文件名
  static const String sharesFileName = 'shares.json';

  /// WebSocket 心跳间隔（毫秒）
  static const int heartbeatInterval = 15000;

  /// WebSocket 重连间隔（毫秒）
  static const int reconnectInterval = 5000;
}
