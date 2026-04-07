/// 全局常量配置
///
/// 生产环境 HTTPS 线路由 [ServerEndpoints] / 设置「服务器线路」解析；
/// 此处 [apiBaseUrl] 仅作未注入前的占位及本地调试（与 [DeviceManager] 初始值一致）。
class AppConstants {
  AppConstants._();

  /// REST API 基础地址（本地调试；生产见 `ServerEndpoints`）
  // static const String apiBaseUrl = 'https://api.etedrop.com';
  static const String apiBaseUrl = 'http://43.153.143.37:40321';
  // static const String apiBaseUrl = 'http://192.168.1.9:3000';

  /// 信令服务器地址（WebRTC 文件传输用）
  // static const String signalingServerUrl = 'wss://api.etedrop.com/api/connect';
  static const String signalingServerUrl =
      'ws://43.153.143.37:40321/api/connect';
  // static const String signalingServerUrl = 'ws://192.168.1.9:3000/api/connect';

  /// 设备管理 WebSocket 地址（分享功能用）
  // static const String shareServerUrl = 'wss://api.etedrop.com/api/share';
  static const String shareServerUrl = 'ws://43.153.143.37:40321/api/share';
  // static const String shareServerUrl = 'ws://192.168.1.9:3000/api/share';

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

  /// WebRTC ICE（默认公共 STUN；跨网稳定性最终取决于 TURN）
  static const List<Map<String, dynamic>> pubIceServers = [
    {
      'urls': [
        'stun:stun.cloudflare.com:3478',
        'stun:stun.qq.com:3478',
        'stun:stun.miwifi.com:3478',
        'stun:stun.l.google.com:19302',
        'stun:stun1.l.google.com:19302',
        'stun:stun2.l.google.com:19302',
        'stun:stun3.l.google.com:19302',
        'stun:stun4.l.google.com:19302',
      ],
    },
  ];

  /// 设备配置文件名
  static const String deviceConfigFileName = 'device-config.json';

  /// 分享记录文件名
  static const String sharesFileName = 'shares.json';

  /// WebSocket 心跳间隔（毫秒）
  static const int heartbeatInterval = 30000;

  /// WebSocket 重连间隔（毫秒）
  static const int reconnectInterval = 5000;
}
