import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/constants.dart';
import '../../../core/config/server_endpoints.dart';
import '../../../core/utils/nickname_utils.dart';
import '../../settings/providers/server_line_provider.dart';
import '../models/device_config.dart';
import '../../transfer/services/peer_data_channel.dart';
import 'share_p2p_handler.dart';

enum DeviceConnectionState { disconnected, connecting, connected }

/// 设备管理服务
class DeviceManager {
  DeviceManager() {
    final boot = resolveServerEndpointsSync();
    _apiBaseUrl = boot.apiBaseUrl;
    _shareServerUrl = boot.shareServerUrl;
    _pubIceServers = AppConstants.pubIceServersForRegion(
      mainlandStunPreferred: boot.mainlandStunPreferred,
    );
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
  final Map<String, PeerDataChannel> _peerChannels = {};
  final Map<String, Completer<void>> _peerOpenWaiters = {};
  final _peerMessageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// 由 [ServerEndpoints] / [resolveServerEndpointsSync] 初始化，随后随 [applyEndpoints] 与线路设置同步。
  late String _apiBaseUrl;
  late String _shareServerUrl;
  late List<Map<String, dynamic>> _pubIceServers;

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

  String _generateDeviceId() {
    // Keep the identifier short enough to type while retaining six digits.
    final value = Random.secure().nextInt(1000000);
    return value.toString().padLeft(6, '0');
  }

  bool _isShortDeviceId(String? id) =>
      id != null && RegExp(r'^\d{6}$').hasMatch(id);

  /// UI 通过此 stream 监听状态变化
  Stream<int> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get peerMessageStream =>
      _peerMessageController.stream;

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
        var changed = false;
        if (!_isShortDeviceId(_config?.deviceId)) {
          // Migrate UUID-era configurations to the new six-digit format.
          _config = _config!.copyWith(deviceId: _generateDeviceId());
          changed = true;
        }
        if (_looksLikeDefaultPlaceholderName(_config?.deviceName)) {
          // Replace the default placeholder name with a locale-based nickname.
          _config = _config!.copyWith(
            deviceName: _randomNicknameForSystemLocale(),
          );
          changed = true;
        }
        if (changed) {
          await _saveConfig();
        }
        _setState(_state);
        return _config!;
      }
    } catch (_) {}

    _config = DeviceConfig(
      deviceId: _generateDeviceId(),
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
    _pubIceServers = AppConstants.pubIceServersForRegion(
      mainlandStunPreferred: endpoints.mainlandStunPreferred,
    );
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
        final fromId = data['fromDeviceId'] as String?;
        final signal = data['data'];
        if (fromId != null && fromId.isNotEmpty && signal is Map) {
          unawaited(
            _handlePeerSignal(fromId, Map<String, dynamic>.from(signal)),
          );
        }
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

  PeerDataChannel _createPeerChannel(String peerId, {required bool initiator}) {
    final existing = _peerChannels[peerId];
    if (existing != null) return existing;

    final open = _peerOpenWaiters.putIfAbsent(peerId, Completer<void>.new);
    late final PeerDataChannel channel;
    channel = PeerDataChannel(
      configuration: {'iceServers': _pubIceServers},
      initializeDataChannel: initiator,
    );
    channel.onSDP = (sdp) {
      _sendPeerSignal(peerId, {
        'kind': 'sdp',
        'sdp': {'sdp': sdp.sdp, 'type': sdp.type},
      });
    };
    channel.onICECandidate = (candidate) {
      _sendPeerSignal(peerId, {
        'kind': 'candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    channel.onOpen = () {
      if (!open.isCompleted) open.complete();
    };
    channel.onReceive = (value, {required size, required duration}) async {
      if (value is! String) return;
      try {
        final message = jsonDecode(value);
        if (message is Map) {
          _peerMessageController.add({
            'fromDeviceId': peerId,
            ...Map<String, dynamic>.from(message),
          });
        }
      } catch (_) {}
    };
    channel.onDispose = () {
      if (_peerChannels[peerId] == channel) {
        _peerChannels.remove(peerId);
      }
      final waiter = _peerOpenWaiters.remove(peerId);
      if (waiter != null && !waiter.isCompleted) {
        waiter.completeError(Exception('WebRTC 连接已断开'));
      }
    };
    _peerChannels[peerId] = channel;
    if (initiator) {
      unawaited(channel.startOffer());
    }
    return channel;
  }

  void _sendPeerSignal(String peerId, Map<String, dynamic> signal) {
    if (!isConnected) return;
    _ws?.sink.add(
      jsonEncode({'type': 'peer-connect', 'deviceId': peerId, 'data': signal}),
    );
  }

  Future<void> _handlePeerSignal(
    String peerId,
    Map<String, dynamic> signal,
  ) async {
    final kind = signal['kind'];
    if (kind == 'sdp') {
      final raw = signal['sdp'];
      if (raw is! Map) return;
      final channel = _createPeerChannel(peerId, initiator: false);
      await channel.setRemoteSDP(
        RTCSessionDescription(raw['sdp'] as String?, raw['type'] as String?),
      );
      return;
    }
    if (kind == 'candidate') {
      final raw = signal['candidate'];
      if (raw is! Map) return;
      final channel = _createPeerChannel(peerId, initiator: false);
      await channel.addICECandidate(
        RTCIceCandidate(
          raw['candidate'] as String?,
          raw['sdpMid'] as String?,
          (raw['sdpMLineIndex'] as num?)?.toInt(),
        ),
      );
    }
  }

  Future<void> sendPeerData(String peerId, Map<String, dynamic> message) async {
    if (!isConnected) throw Exception('信令服务未连接');
    final channel = _createPeerChannel(peerId, initiator: true);
    await channel.ready;
    final waiter = _peerOpenWaiters[peerId];
    if (waiter != null && !waiter.isCompleted) {
      await waiter.future.timeout(const Duration(seconds: 20));
    }
    await channel.sendData(jsonEncode(message));
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
        iceServers: _pubIceServers,
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
    final channels = [..._peerChannels.values];
    _peerChannels.clear();
    for (final channel in channels) {
      channel.dispose();
    }
    for (final waiter in _peerOpenWaiters.values) {
      if (!waiter.isCompleted) waiter.completeError(Exception('连接已断开'));
    }
    _peerOpenWaiters.clear();
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
    _peerMessageController.close();
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
