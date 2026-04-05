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

  /// 应用版本
  static const String version = '1.0.0';

  /// 更新清单（自建 HTTP）：返回 JSON
  static const String updateManifestUrl =
      'https://api.etedrop.com/version.json';
  // static const String updateManifestUrl =
  //     'http://192.168.1.9:3000/version.json';

  /// iOS/Android 未来上架后可配置商店链接（用于“去商店更新”跳转）
  static const String iosStoreUrl = '';
  static const String androidStoreUrl = '';

  /// WebRTC DataChannel 默认分块大小
  static const int defaultBlockSize = 32768;

  /// 设备配置文件名
  static const String deviceConfigFileName = 'device-config.json';

  /// 分享记录文件名
  static const String sharesFileName = 'shares.json';

  /// WebSocket 心跳间隔（毫秒）
  static const int heartbeatInterval = 30000;

  /// WebSocket 重连间隔（毫秒）
  static const int reconnectInterval = 5000;
}
