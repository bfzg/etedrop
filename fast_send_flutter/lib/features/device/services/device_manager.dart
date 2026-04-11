import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/constants.dart';
import '../../../core/config/server_endpoints.dart';
import '../../../core/utils/nickname_utils.dart';
import '../../settings/providers/server_line_provider.dart';
import '../models/device_config.dart';
import 'share_p2p_handler.dart';

enum DeviceConnectionState { disconnected, connecting, connected }

/// 设备管理服务
class DeviceManager {
  DeviceManager() {
    final boot = resolveServerEndpointsSync();
    _apiBaseUrl = boot.apiBaseUrl;
    _shareServerUrl = boot.shareServerUrl;
  }

  DeviceConfig? _config;
  WebSocketChannel? _ws;
  DeviceConnectionState _state = DeviceConnectionState.disconnected;
  String? _lastError;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  StreamSubscription? _wsSubscription;
  bool _disposed = false;
  final Map<String, ShareP2PHandler> _p2pHandlers = {};

  /// 由 [ServerEndpoints] / [resolveServerEndpointsSync] 初始化，随后随 [applyEndpoints] 与线路设置同步。
  late String _apiBaseUrl;
  late String _shareServerUrl;

  final _stateController = StreamController<int>.broadcast();
  int _stateTick = 0;

  String _randomNicknameForSystemLocale() {
    final lang = PlatformDispatcher.instance.locale.languageCode;
    return generateRandomNicknameForLanguageCode(lang);
  }

  bool _looksLikeDefaultPlaceholderName(String? name) {
    final n = name?.trim().toLowerCase();
    if (n == null || n.isEmpty) return true;
    // Current app default was Platform.localHostname (commonly "localhost").
    return n == 'localhost' || n == 'unknown';
  }

  /// UI 通过此 stream 监听状态变化
  Stream<int> get stateStream => _stateController.stream;

  DeviceConfig? get config => _config;
  DeviceConnectionState get state => _state;
  bool get isConnected => _state == DeviceConnectionState.connected;
  bool get isConnecting => _state == DeviceConnectionState.connecting;
  String? get lastError => _lastError;

  void _setState(DeviceConnectionState s, {String? error}) {
    _state = s;
    _lastError = error;
    if (!_disposed && !_stateController.isClosed) {
      _stateTick += 1;
      _stateController.add(_stateTick);
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
        if (_looksLikeDefaultPlaceholderName(_config?.deviceName)) {
          // Replace the default placeholder name with a locale-based nickname.
          _config = _config!.copyWith(
            deviceName: _randomNicknameForSystemLocale(),
          );
          await _saveConfig();
        }
        _setState(_state);
        return _config!;
      }
    } catch (_) {}

    _config = DeviceConfig(
      deviceId: const Uuid().v4(),
      deviceName: _randomNicknameForSystemLocale(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      avatar: Random().nextInt(kMemojiCount) + 1,
    );
    await _saveConfig();
    _setState(_state);
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

  Future<void> setAvatar(int avatar) async {
    if (_config == null) await loadConfig();
    _config = _config!.copyWith(avatar: avatar);
    await _saveConfig();
    _setState(_state);
  }

  /// 切换线路（设置页 / 启动时调用）。地址变化且当前已连接时会断开并重连。
  void applyEndpoints(ServerEndpoints endpoints) {
    final changed =
        _apiBaseUrl != endpoints.apiBaseUrl ||
        _shareServerUrl != endpoints.shareServerUrl;
    _apiBaseUrl = endpoints.apiBaseUrl;
    _shareServerUrl = endpoints.shareServerUrl;
    if (!changed) return;
    if (isConnected || isConnecting) {
      disconnect();
      unawaited(connectToServer());
    }
  }

  /// 连接到信令服务器
  Future<void> connectToServer() async {
    if (_state == DeviceConnectionState.connected ||
        _state == DeviceConnectionState.connecting) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _setState(DeviceConnectionState.connecting);

    final config = await loadConfig();

    try {
      _ws = WebSocketChannel.connect(Uri.parse(_shareServerUrl));

      // WebSocketChannel.connect 不会抛同步异常，需要等 ready
      await _ws!.ready;

      if (_disposed) return;

      _ws!.sink.add(
        jsonEncode({
          'type': 'device-online',
          'deviceId': config.deviceId,
          'deviceName': config.deviceName,
        }),
      );

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
        final peerId = data['peerId'] as String?;
        if (offerData is Map<String, dynamic>) {
          final id = (peerId != null && peerId.isNotEmpty) ? peerId : 'default';
          unawaited(_onOffer(offerData, id));
        }
        break;
      case 'ice-candidate':
        final iceData = data['data'];
        final peerId = data['peerId'] as String?;
        if (iceData is Map<String, dynamic>) {
          final id = (peerId != null && peerId.isNotEmpty) ? peerId : 'default';
          unawaited(_p2pHandlers[id]?.handleIceCandidate(iceData));
        }
        break;
    }
  }

  /// 同一 peerId 复用 [ShareP2PHandler]，由 [ShareP2PHandler.handleOffer] 内关旧 PC。
  /// 勿在每次 offer 时 dispose 再 new：会与 handleOffer 内逻辑重复，且易在传输中途误拆连接。
  Future<void> _onOffer(Map<String, dynamic> offerData, String peerId) async {
    ShareP2PHandler? handler = _p2pHandlers[peerId];
    if (handler == null) {
      late ShareP2PHandler h;
      h = ShareP2PHandler(
        sendSignaling: (msg) =>
            _ws?.sink.add(jsonEncode({...msg, 'peerId': peerId})),
        onSessionEnded: () {
          unawaited(_removeP2pSession(peerId, h));
        },
      );
      _p2pHandlers[peerId] = h;
      handler = h;
    }
    await handler.handleOffer(offerData);
  }

  Future<void> _removeP2pSession(String peerId, ShareP2PHandler handler) async {
    if (_p2pHandlers[peerId] == handler) {
      _p2pHandlers.remove(peerId);
    }
    await handler.dispose();
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
    for (final h in _p2pHandlers.values) {
      unawaited(h.dispose());
    }
    _p2pHandlers.clear();
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

  ({bool connected, String? deviceId}) get connectionStatus =>
      (connected: isConnected, deviceId: _config?.deviceId);

  String getShareUrl(String shareCode) {
    if (_config == null) return '';
    return '$_apiBaseUrl/share/${_config!.deviceId}/$shareCode';
  }

  /// 把原始异常转为用户友好文案
  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Connection refused')) {
      return '无法连接服务器 ($_shareServerUrl)';
    }
    if (s.contains('SocketException')) {
      return '网络错误: $s';
    }
    return s;
  }
}
