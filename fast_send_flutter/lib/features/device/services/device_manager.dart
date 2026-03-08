import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/constants.dart';
import '../models/device_config.dart';
import 'share_p2p_handler.dart';

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
}

/// 设备管理服务
class DeviceManager {
  DeviceConfig? _config;
  WebSocketChannel? _ws;
  DeviceConnectionState _state = DeviceConnectionState.disconnected;
  String? _lastError;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _wsSubscription;
  bool _disposed = false;
  ShareP2PHandler? _p2pHandler;

  final _stateController = StreamController<void>.broadcast();

  /// UI 通过此 stream 监听状态变化
  Stream<void> get stateStream => _stateController.stream;

  DeviceConfig? get config => _config;
  DeviceConnectionState get state => _state;
  bool get isConnected => _state == DeviceConnectionState.connected;
  bool get isConnecting => _state == DeviceConnectionState.connecting;
  String? get lastError => _lastError;

  void _setState(DeviceConnectionState s, {String? error}) {
    _state = s;
    _lastError = error;
    if (!_disposed && !_stateController.isClosed) {
      _stateController.add(null);
    }
  }

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
    } catch (_) {}

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

  Future<bool> setDeviceName(String name) async {
    if (_config == null) await loadConfig();
    _config = _config!.copyWith(deviceName: name);
    await _saveConfig();
    _setState(_state);
    return true;
  }

  /// 连接到信令服务器
  Future<void> connectToServer() async {
    if (_state == DeviceConnectionState.connected ||
        _state == DeviceConnectionState.connecting) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _setState(DeviceConnectionState.connecting);

    final config = await loadConfig();

    try {
      _ws = WebSocketChannel.connect(
        Uri.parse(AppConstants.shareServerUrl),
      );

      // WebSocketChannel.connect 不会抛同步异常，需要等 ready
      await _ws!.ready;

      if (_disposed) return;

      _ws!.sink.add(jsonEncode({
        'type': 'device-online',
        'deviceId': config.deviceId,
        'deviceName': config.deviceName,
      }));

      _setState(DeviceConnectionState.connected);

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(milliseconds: AppConstants.heartbeatInterval),
        (_) {
          if (isConnected) {
            _ws?.sink.add(jsonEncode({'type': 'heartbeat'}));
          }
        },
      );

      _wsSubscription?.cancel();
      _wsSubscription = _ws!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _handleMessage(msg);
          } catch (_) {}
        },
        onError: (error) {
          _cleanup(error: _friendlyError(error));
          _scheduleReconnect();
        },
        onDone: () {
          _cleanup(error: '连接已断开，正在重连...');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (_disposed) return;
      _cleanup(error: _friendlyError(e));
      _scheduleReconnect();
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'device-online-ack':
        break;
      case 'peer-connect':
        break;
      case 'ping':
        _ws?.sink.add(jsonEncode({'type': 'heartbeat'}));
        break;
      case 'offer':
        final offerData = data['data'];
        if (offerData is Map<String, dynamic>) {
          _onOffer(offerData);
        }
        break;
      case 'ice-candidate':
        final iceData = data['data'];
        if (iceData is Map<String, dynamic>) {
          _p2pHandler?.handleIceCandidate(iceData);
        }
        break;
    }
  }

  Future<void> _onOffer(Map<String, dynamic> offerData) async {
    await _p2pHandler?.dispose();
    _p2pHandler = ShareP2PHandler(
      sendSignaling: (msg) => _ws?.sink.add(jsonEncode(msg)),
    );
    await _p2pHandler!.handleOffer(offerData);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      const Duration(milliseconds: AppConstants.reconnectInterval),
      () {
        _reconnectTimer = null;
        if (!_disposed) connectToServer();
      },
    );
  }

  /// 清理连接资源（不清 config/reconnect timer）
  void _cleanup({String? error}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _p2pHandler?.dispose();
    _p2pHandler = null;
    _ws?.sink.close().catchError((_) {});
    _ws = null;
    _setState(DeviceConnectionState.disconnected, error: error);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _stateController.close();
  }

  ({bool connected, String? deviceId}) get connectionStatus => (
        connected: isConnected,
        deviceId: _config?.deviceId,
      );

  String getShareUrl(String shareCode) {
    if (_config == null) return '';
    return '${AppConstants.shareLinkBaseUrl}/share/${_config!.deviceId}/$shareCode';
  }

  /// 把原始异常转为用户友好文案
  static String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Connection refused')) {
      return '无法连接服务器 (${AppConstants.shareServerUrl})';
    }
    if (s.contains('SocketException')) {
      return '网络错误: $s';
    }
    return s;
  }
}
