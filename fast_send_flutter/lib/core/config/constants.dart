/// 全局常量配置
class AppConstants {
  AppConstants._();

  /// 信令服务器地址（WebRTC 文件传输用）
  static const String signalingServerUrl = 'wss://fastsend.ing/api/connect';

  /// 设备管理 WebSocket 地址（分享功能用）
  static const String shareServerUrl = 'ws://localhost:3000/api/share';

  /// Web 端分享链接基础 URL
  static const String webBaseUrl = 'https://fastsend.kieng.cn';

  /// 应用名称
  static const String appName = 'FastSend';

  /// 应用版本
  static const String version = '1.0.0';

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
