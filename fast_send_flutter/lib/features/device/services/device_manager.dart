import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/constants.dart';
import '../models/device_config.dart';

/// 设备管理服务
/// 对应 Electron: src/main/device-manager.ts
class DeviceManager {
  DeviceConfig? _config;
  WebSocketChannel? _ws;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _wsSubscription;

  DeviceConfig? get config => _config;
  bool get isConnected => _isConnected;

  /// 加载设备配置（首次启动时自动生成）
  /// 对应 Electron: loadDeviceConfig()
  Future<DeviceConfig> loadConfig() async {
    if (_config != null) return _config!;

    final appDir = await getApplicationSupportDirectory();
    final configPath = p.join(appDir.path, AppConstants.deviceConfigFileName);
    final file = File(configPath);

    try {
      if (await file.exists()) {
        final data = await file.readAsString();
        _config = DeviceConfig.fromJson(jsonDecode(data));
        return _config!;
      }
    } catch (_) {
      // 配置损坏，重新生成
    }

    // 首次启动，生成新配置
    _config = DeviceConfig(
      deviceId: const Uuid().v4(),
      deviceName: Platform.localHostname,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveConfig();
    return _config!;
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    final appDir = await getApplicationSupportDirectory();
    final configPath = p.join(appDir.path, AppConstants.deviceConfigFileName);
    await File(configPath).writeAsString(jsonEncode(_config!.toJson()));
  }

  /// 设置设备名称
  /// 对应 Electron: setDeviceName()
  Future<bool> setDeviceName(String name) async {
    if (_config == null) await loadConfig();
    _config = _config!.copyWith(deviceName: name);
    await _saveConfig();
    return true;
  }

  /// 连接到信令服务器
  /// 对应 Electron: connectToServer()
  Future<void> connectToServer() async {
    if (_isConnected) return;

    final config = await loadConfig();

    try {
      _ws = WebSocketChannel.connect(
        Uri.parse(AppConstants.shareServerUrl),
      );

      // 发送设备上线消息
      _ws!.sink.add(jsonEncode({
        'type': 'device-online',
        'deviceId': config.deviceId,
        'deviceName': config.deviceName,
      }));

      _isConnected = true;

      // 启动心跳
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(milliseconds: AppConstants.heartbeatInterval),
        (_) {
          if (_isConnected) {
            _ws?.sink.add(jsonEncode({'type': 'heartbeat'}));
          }
        },
      );

      // 监听消息
      _wsSubscription = _ws!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            _handleMessage(message as Map<String, dynamic>);
          } catch (e) {
            // 解析失败，忽略
          }
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _ws = null;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// 处理服务端消息
  /// 对应 Electron: handleServerMessage()
  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'device-online-ack':
        // 设备上线确认
        break;
      case 'peer-connect':
        // 有浏览器想连接
        // TODO: 处理 WebRTC 信令转发
        break;
      case 'ping':
        _ws?.sink.add(jsonEncode({'type': 'heartbeat'}));
        break;
    }
  }

  /// 定时重连
  /// 对应 Electron: scheduleReconnect()
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(milliseconds: AppConstants.reconnectInterval),
      () {
        _reconnectTimer = null;
        connectToServer();
      },
    );
  }

  /// 断开连接
  /// 对应 Electron: disconnectFromServer()
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _ws?.sink.close();
    _ws = null;
    _isConnected = false;
  }

  /// 获取连接状态
  /// 对应 Electron: getConnectionStatus()
  ({bool connected, String? deviceId}) get connectionStatus => (
        connected: _isConnected,
        deviceId: _config?.deviceId,
      );

  /// 生成分享链接
  /// 对应 Electron: getShareUrl()
  String getShareUrl(String shareCode) {
    if (_config == null) return '';
    return '${AppConstants.shareLinkBaseUrl}/share/${_config!.deviceId}/$shareCode';
  }
}
