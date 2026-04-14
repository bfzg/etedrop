import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/constants.dart';
import '../../../l10n/l10n_utils.dart';
import 'peer_data_channel.dart';

/// 信令状态
/// 对应 Electron: src/utils/SignalingService.ts → SignalingStatus
enum SignalingStatus {
  connecting,
  connected,
  waiting,
  paired,
  error,
  timeout,
  closed,
}

/// 信令回调
/// 对应 Electron: src/utils/SignalingService.ts → SignalingCallbacks
class SignalingCallbacks {
  final void Function(SignalingStatus status)? onStatusChange;
  final void Function(String code)? onCode;
  final void Function()? onPeerConnected;
  final void Function()? onPeerDisconnected;
  final void Function(String error)? onError;
  final void Function()? onDataChannelOpen;
  final Future<void> Function(dynamic data, {required int size, required int duration})?
      onReceive;

  SignalingCallbacks({
    this.onStatusChange,
    this.onCode,
    this.onPeerConnected,
    this.onPeerDisconnected,
    this.onError,
    this.onDataChannelOpen,
    this.onReceive,
  });
}

/// 信令服务 — 用于建立 WebRTC 连接
/// 对应 Electron: src/utils/SignalingService.ts → SignalingService class
class SignalingService {
  WebSocketChannel? _ws;
  PeerDataChannel? _pdc;
  SignalingCallbacks _callbacks;
  final String _serverUrl;
  final List<Map<String, dynamic>> _iceServers;
  SignalingStatus _status = SignalingStatus.connecting;
  String _code = '';
  StreamSubscription? _wsSubscription;

  /// [iceServers] 为空时使用与「全球线」一致的 STUN 顺序；与 [DeviceManager] 场景请传入
  /// [AppConstants.pubIceServersForRegion] 以与当前 API 线路对齐。
  SignalingService(
    this._serverUrl, {
    SignalingCallbacks? callbacks,
    List<Map<String, dynamic>>? iceServers,
  })  : _callbacks = callbacks ?? SignalingCallbacks(),
        _iceServers = iceServers ??
            AppConstants.pubIceServersForRegion(mainlandStunPreferred: false);

  SignalingStatus get status => _status;
  String get code => _code;
  PeerDataChannel? get peerDataChannel => _pdc;

  void _setStatus(SignalingStatus status) {
    _status = status;
    _callbacks.onStatusChange?.call(status);
  }

  /// 作为发送方连接
  /// 对应 Electron: connectAsSender()
  Future<String> connectAsSender() {
    final completer = Completer<String>();

    final originalOnCode = _callbacks.onCode;
    _callbacks = SignalingCallbacks(
      onStatusChange: _callbacks.onStatusChange,
      onCode: (code) {
        originalOnCode?.call(code);
        if (!completer.isCompleted) completer.complete(code);
      },
      onPeerConnected: _callbacks.onPeerConnected,
      onPeerDisconnected: _callbacks.onPeerDisconnected,
      onError: (error) {
        _callbacks.onError?.call(error);
        if (!completer.isCompleted) completer.completeError(Exception(error));
      },
      onDataChannelOpen: _callbacks.onDataChannelOpen,
      onReceive: _callbacks.onReceive,
    );

    _connect();

    // 连接成功后发送 send 请求
    // WebSocketChannel 连接即打开，直接发送
    Future.delayed(const Duration(milliseconds: 100), () {
      _ws?.sink.add(jsonEncode({'type': 'send'}));
    });

    return completer.future;
  }

  /// 作为接收方连接
  /// 对应 Electron: connectAsReceiver(code)
  Future<void> connectAsReceiver(String code) {
    final completer = Completer<void>();

    final originalOnPeerConnected = _callbacks.onPeerConnected;
    _callbacks = SignalingCallbacks(
      onStatusChange: _callbacks.onStatusChange,
      onCode: _callbacks.onCode,
      onPeerConnected: () {
        originalOnPeerConnected?.call();
        if (!completer.isCompleted) completer.complete();
      },
      onPeerDisconnected: _callbacks.onPeerDisconnected,
      onError: (error) {
        _callbacks.onError?.call(error);
        if (!completer.isCompleted) completer.completeError(Exception(error));
      },
      onDataChannelOpen: _callbacks.onDataChannelOpen,
      onReceive: _callbacks.onReceive,
    );

    _connect();

    Future.delayed(const Duration(milliseconds: 100), () {
      _ws?.sink.add(jsonEncode({'type': 'receive', 'code': code}));
    });

    return completer.future;
  }

  /// 建立 WebSocket 连接
  /// 对应 Electron: connect()
  void _connect() {
    _setStatus(SignalingStatus.connecting);

    try {
      _ws = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _setStatus(SignalingStatus.connected);

      _wsSubscription = _ws!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _handleMessage(msg);
          } catch (e) {
            // 解析失败，忽略
          }
        },
        onError: (error) {
          _setStatus(SignalingStatus.error);
          _callbacks.onError?.call(loadAppLocalizationsSync().webSocketError);
        },
        onDone: () {
          if (_status == SignalingStatus.connecting) {
            _setStatus(SignalingStatus.error);
            _callbacks.onError?.call(
              loadAppLocalizationsSync().signalingConnectFailed,
            );
          } else if (_status == SignalingStatus.waiting) {
            _setStatus(SignalingStatus.timeout);
            _callbacks.onError?.call(
              loadAppLocalizationsSync().signalingWaitTimeout,
            );
          } else {
            _setStatus(SignalingStatus.closed);
          }
        },
      );
    } catch (e) {
      _setStatus(SignalingStatus.error);
      _callbacks.onError?.call(
        loadAppLocalizationsSync().signalingConnectFailed,
      );
    }
  }

  /// 处理信令消息
  /// 对应 Electron: handleMessage()
  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'code':
        _code = '${data['code'] ?? ''}';
        _setStatus(SignalingStatus.waiting);
        _callbacks.onCode?.call(_code);
        _initPDC(false);
        break;

      case 'status':
        if (data['code'] == 404) {
          _setStatus(SignalingStatus.error);
          _callbacks.onError?.call(
            loadAppLocalizationsSync().invalidPickupCode,
          );
          dispose();
        } else if (data['code'] == 0) {
          _initPDC(true);
        }
        break;

      case 'sdp':
        final sdpData = data['data'] as Map<String, dynamic>;
        _pdc?.setRemoteSDP(_createRTCSessionDescription(sdpData));
        break;

      case 'candidate':
        final candidateData = data['data'] as Map<String, dynamic>;
        _pdc?.addICECandidate(_createRTCIceCandidate(candidateData));
        break;

      case 'err':
        _setStatus(SignalingStatus.error);
        _callbacks.onError?.call('${data['msg'] ?? '错误码: ${data['data']}'}');
        break;

      case 'ping':
        // 心跳，忽略
        break;
    }
  }

  /// 初始化 PeerDataChannel
  /// 对应 Electron: initPDC()
  void _initPDC(bool initializeDataChannel) {
    _pdc = PeerDataChannel(
      configuration: {
        'iceServers': _iceServers,
      },
      initializeDataChannel: initializeDataChannel,
    );

    _pdc!.onSDP = (sdp) {
      _ws?.sink.add(jsonEncode({
        'type': 'sdp',
        'data': {'sdp': sdp.sdp, 'type': sdp.type},
      }));
    };

    _pdc!.onICECandidate = (candidate) {
      _ws?.sink.add(jsonEncode({
        'type': 'candidate',
        'data': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      }));
    };

    _pdc!.onConnected = () {
      _setStatus(SignalingStatus.paired);
      _callbacks.onPeerConnected?.call();
    };

    _pdc!.onDispose = () {
      _callbacks.onPeerDisconnected?.call();
    };

    _pdc!.onOpen = () {
      _callbacks.onDataChannelOpen?.call();
    };

    _pdc!.onError = (err) {
      _callbacks.onError?.call(err.toString());
    };

    if (_callbacks.onReceive != null) {
      _pdc!.onReceive = _callbacks.onReceive;
    }
  }

  /// 发送数据
  /// 对应 Electron: sendData()
  Future<void> sendData(dynamic data) async {
    if (_pdc == null) {
      throw Exception('PeerDataChannel not initialized');
    }
    return _pdc!.sendData(data);
  }

  /// 关闭连接
  /// 对应 Electron: dispose()
  void dispose() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _ws?.sink.close();
    _ws = null;
    _pdc?.dispose();
    _pdc = null;
    _setStatus(SignalingStatus.closed);
  }

  // ---- 辅助方法：构造 flutter_webrtc 对象 ----

  RTCSessionDescription _createRTCSessionDescription(Map<String, dynamic> data) {
    return RTCSessionDescription(data['sdp'], data['type']);
  }

  RTCIceCandidate _createRTCIceCandidate(Map<String, dynamic> data) {
    return RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
  }
}
