import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 事件队列，保证消息按顺序处理
/// 对应 Electron: src/utils/PeerDataChannel.ts → EventQueue
class EventQueue<T> {
  Future<void> _tail = Future.value();
  final Future<void> Function(T) _handler;

  EventQueue(this._handler);

  void enqueue(T event) {
    _tail = _tail.then((_) => _handler(event)).catchError((e) {
      // ignore
    });
  }
}

/// 封装 WebRTC DataChannel 的点对点数据传输
/// 对应 Electron: src/utils/PeerDataChannel.ts → PeerDataChannel class
class PeerDataChannel {
  static const int defaultBlockSize = 32768;

  late RTCPeerConnection _pc;
  RTCDataChannel? _dc;
  final int _blockSize;
  late EventQueue<dynamic> _eventQueue;

  // 接收状态
  int _receiveStartTime = 0;
  int _receiveOffset = 0;
  int _receiveCount = 0;
  String _receiveType = '';
  final List<Uint8List> _receiveChunks = [];

  // 回调
  /// 对应 Electron: onSDP
  void Function(RTCSessionDescription sdp)? onSDP;

  /// 对应 Electron: onICECandidate
  void Function(RTCIceCandidate candidate)? onICECandidate;

  /// 对应 Electron: onReceive
  Future<void> Function(dynamic data, {required int size, required int duration})?
      onReceive;

  /// 对应 Electron: onError
  void Function(Object error)? onError;

  /// 对应 Electron: onConnected
  void Function()? onConnected;

  /// 对应 Electron: onDispose
  void Function()? onDispose;

  /// 对应 Electron: onOpen
  void Function()? onOpen;

  /// 创建 PeerDataChannel
  /// 对应 Electron: constructor(config)
  PeerDataChannel({
    Map<String, dynamic>? configuration,
    int blockSize = defaultBlockSize,
    bool initializeDataChannel = false,
  }) : _blockSize = blockSize {
    _eventQueue = EventQueue<dynamic>(_onData);
    _init(configuration ?? {}, initializeDataChannel);
  }

  Future<void> _init(
    Map<String, dynamic> configuration,
    bool initializeDataChannel,
  ) async {
    _pc = await createPeerConnection(configuration);
    _setupPeerConnection();

    if (initializeDataChannel) {
      await _initializeDataChannel();
    }
  }

  /// 对应 Electron: setupPeerConnection()
  void _setupPeerConnection() {
    _pc.onDataChannel = _handleDataChannel;
    _pc.onRenegotiationNeeded = _reNegotiation;
    _pc.onIceCandidate = (candidate) {
      onICECandidate?.call(candidate);
    };
    _pc.onConnectionState = _handleConnectionStateChange;
  }

  /// 对应 Electron: handleDataChannel()
  void _handleDataChannel(RTCDataChannel dc) {
    _dc = dc;
    _setupDataChannel();
  }

  /// 对应 Electron: initializeDataChannel()
  Future<void> _initializeDataChannel() async {
    _dc = await _pc.createDataChannel(
      'dc',
      RTCDataChannelInit()..ordered = true,
    );
    _setupDataChannel();
  }

  /// 对应 Electron: setupDataChannel()
  void _setupDataChannel() {
    if (_dc == null) return;
    _dc!.onMessage = (msg) {
      if (msg.isBinary) {
        _eventQueue.enqueue(msg.binary);
      } else {
        _eventQueue.enqueue(msg.text);
      }
    };
    _dc!.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        onOpen?.call();
      }
    };
  }

  /// 对应 Electron: handleConnectionStateChange()
  void _handleConnectionStateChange(RTCPeerConnectionState state) {
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      dispose();
      onDispose?.call();
    } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      onConnected?.call();
    }
  }

  /// 对应 Electron: onData() — 消息分帧协议处理
  Future<void> _onData(dynamic data) async {
    if (_receiveOffset == _receiveCount) {
      // 新消息头
      final header = jsonDecode(data is String ? data : utf8.decode(data as Uint8List));
      _receiveStartTime = DateTime.now().millisecondsSinceEpoch;
      _receiveOffset = 0;
      _receiveCount = header['count'] as int;
      _receiveType = header['type'] as String;
      _receiveChunks.clear();
    } else {
      // 数据块
      if (data is Uint8List) {
        _receiveChunks.add(data);
      } else if (data is String) {
        _receiveChunks.add(Uint8List.fromList(utf8.encode(data)));
      }
      _receiveOffset++;

      if (_receiveOffset == _receiveCount) {
        final endTime = DateTime.now().millisecondsSinceEpoch;
        final totalSize = _receiveChunks.fold<int>(0, (sum, c) => sum + c.length);

        dynamic result;
        if (_receiveType == 'string') {
          final builder = BytesBuilder();
          for (final chunk in _receiveChunks) {
            builder.add(chunk);
          }
          result = utf8.decode(builder.toBytes());
        } else {
          final builder = BytesBuilder();
          for (final chunk in _receiveChunks) {
            builder.add(chunk);
          }
          result = builder.toBytes();
        }

        await onReceive?.call(
          result,
          size: totalSize,
          duration: endTime - _receiveStartTime,
        );
        _receiveChunks.clear();
      }
    }
  }

  /// 发送数据（分块）
  /// 对应 Electron: sendData()
  Future<void> sendData(dynamic data) async {
    if (_dc == null) {
      throw Exception('Data channel not initialized');
    }

    final Uint8List bytes;
    final String type;

    if (data is String) {
      bytes = Uint8List.fromList(utf8.encode(data));
      type = 'string';
    } else if (data is Uint8List) {
      bytes = data;
      type = 'object';
    } else {
      throw Exception('Unsupported data type');
    }

    final count = (bytes.length / _blockSize).ceil();

    // 发送头部
    _dc!.send(RTCDataChannelMessage(jsonEncode({'count': count, 'type': type})));

    // 分块发送
    for (int i = 0; i < count; i++) {
      final start = i * _blockSize;
      final end = (start + _blockSize > bytes.length) ? bytes.length : start + _blockSize;
      final chunk = bytes.sublist(start, end);

      _dc!.send(RTCDataChannelMessage.fromBinary(chunk));

      // 简单的流控：等待缓冲区清空
      // TODO: 优化为 bufferedAmountLowThreshold 机制（需验证 flutter_webrtc 支持）
      while ((_dc?.bufferedAmount ?? 0) > _blockSize * 16) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }
  }

  /// 设置远程 SDP
  /// 对应 Electron: setRemoteSDP()
  Future<void> setRemoteSDP(RTCSessionDescription sdp) async {
    try {
      await _pc.setRemoteDescription(sdp);
      if (sdp.type == 'offer') {
        final answer = await _pc.createAnswer();
        await _pc.setLocalDescription(answer);
        onSDP?.call(answer);
      }
    } catch (e) {
      onError?.call(e);
      dispose();
    }
  }

  /// 添加 ICE candidate
  /// 对应 Electron: addICECandidate()
  Future<void> addICECandidate(RTCIceCandidate candidate) async {
    await _pc.addCandidate(candidate);
  }

  /// 重协商
  /// 对应 Electron: reNegotiation()
  Future<void> _reNegotiation() async {
    try {
      final offer = await _pc.createOffer();
      await _pc.setLocalDescription(offer);
      final localDesc = await _pc.getLocalDescription();
      if (localDesc != null) {
        onSDP?.call(localDesc);
      }
    } catch (e) {
      onError?.call(e);
      dispose();
    }
  }

  /// 检查是否连接
  /// 对应 Electron: isConnected()
  bool get isConnected =>
      _pc.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  /// 释放资源
  /// 对应 Electron: dispose()
  void dispose() {
    _dc?.close();
    _dc = null;
    _pc.close();
  }
}
