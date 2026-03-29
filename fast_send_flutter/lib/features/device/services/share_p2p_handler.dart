import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path/path.dart' as p;

import '../../../core/config/constants.dart';
import '../../../services/local_storage_service.dart';
import '../../cloud/cloud_storage_prefs.dart';
import '../../share/services/share_service.dart';

/// 单帧二进制负载（不含 8 字节偏移头），与 AppConstants.defaultBlockSize 对齐便于维护。
int get _dataChunkSize => AppConstants.defaultBlockSize;

/// 从头下载且不超过此大小时走「无偏移头」快速路径（一次读入 + 更少帧），避免每包 8 字节头与 RAF 循环开销。
const int _smallFileFastPathMaxBytes = 30 * 1024 * 1024; // 30mb

/// 小文件尝试单帧发送的上限（超过则改为无头多分片，避开部分环境 DataChannel 单帧上限）。
const int _smallFileSingleSendMaxBytes = 128 * 1024;

/// 快速路径下无头分片的负载大小（可略大于带前缀路径）。
const int _smallFileLegacyChunkBytes = 64 * 1024;

/// 分享页（share-page-app）经 WebRTC DataChannel 从本机「网盘」存储目录拉取文件；
/// 小文件可走无头快速路径；大文件或断点续传走 8 字节偏移前缀分片（与 share-page-app 一致）。
class ShareP2PHandler {
  final void Function(Map<String, dynamic> message) sendSignaling;
  final ShareService _shareService = ShareService();

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  final List<Map<String, dynamic>> _pendingCandidates = [];

  String? _currentShareCode;
  bool _passwordVerified = false;
  bool _initialized = false;

  ShareP2PHandler({required this.sendSignaling});

  String get _storageDir =>
      LocalStorageService.instance.get<String>(kCloudStorageDirKey) ?? '';

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await _shareService.init();
      _initialized = true;
    }
  }

  Future<void> handleOffer(Map<String, dynamic> data) async {
    await _ensureInit();

    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        sendSignaling({
          'type': 'ice-candidate',
          'data': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _pc!.onDataChannel = (channel) {
      _dc = channel;
      _setupDataChannel();
    };

    await _pc!.setRemoteDescription(
      RTCSessionDescription(
        data['sdp'] as String?,
        data['type'] as String? ?? 'offer',
      ),
    );

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    sendSignaling({
      'type': 'answer',
      'data': {'sdp': answer.sdp, 'type': answer.type},
    });

    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(
        RTCIceCandidate(
          c['candidate'] as String?,
          c['sdpMid'] as String?,
          c['sdpMLineIndex'] as int?,
        ),
      );
    }
    _pendingCandidates.clear();
  }

  Future<void> handleIceCandidate(Map<String, dynamic> data) async {
    if (_pc == null) {
      _pendingCandidates.add(data);
      return;
    }
    try {
      await _pc!.addCandidate(
        RTCIceCandidate(
          data['candidate'] as String?,
          data['sdpMid'] as String?,
          data['sdpMLineIndex'] as int?,
        ),
      );
    } catch (_) {
      // 连接已关闭或正在释放时，迟到的 ICE candidate 会报 peerConnection not found，忽略即可
    }
  }

  void _setupDataChannel() {
    _dc!.onMessage = (RTCDataChannelMessage msg) {
      if (msg.isBinary) return;
      try {
        final data = jsonDecode(msg.text) as Map<String, dynamic>;
        _handleDcMessage(data);
      } catch (_) {}
    };
  }

  void _handleDcMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'share-request':
        _onShareRequest(msg['shareCode'] as String? ?? '');
        break;
      case 'share-verify':
        _onShareVerify(msg['password'] as String? ?? '');
        break;
      case 'download-start':
        unawaited(_onDownloadStart(msg));
        break;
    }
  }

  void _onShareRequest(String shareCode) {
    _currentShareCode = shareCode;
    _passwordVerified = false;

    final info = _shareService.getShareMeta(shareCode);
    if (info == null) {
      _sendJson({'type': 'error', 'code': 'NOT_FOUND', 'message': '分享不存在或已过期'});
      return;
    }

    _sendJson({
      'type': 'share-info',
      'fileName': info.fileName,
      'fileSize': info.size,
      'hasPassword': info.hasPassword,
    });
  }

  void _onShareVerify(String password) {
    if (_currentShareCode == null) return;
    final valid = _shareService.verifySharePassword(
      _currentShareCode!,
      password,
    );
    _passwordVerified = valid;
    _sendJson({
      'type': 'verify-result',
      'success': valid,
      if (!valid) 'error': '密码错误',
    });
  }

  /// 二进制帧格式：`[0..8)` 大端 uint64 文件内绝对偏移，`[8..end)` 为数据（与 share-page-app 一致）。
  Uint8List _encodeOffsetPrefixedChunk(int fileOffset, Uint8List payload) {
    final out = Uint8List(8 + payload.length);
    ByteData.sublistView(out, 0, 8).setUint64(0, fileOffset, Endian.big);
    out.setRange(8, 8 + payload.length, payload);
    return out;
  }

  /// 小文件：整文件读入后发送（单帧或少量无头二进制），与 share-page-app `chunkPrefixBytes` 缺省/0 分支对应。
  Future<void> _sendSmallFileFastPath(Uint8List bytes) async {
    if (bytes.isEmpty) return;

    if (bytes.length <= _smallFileSingleSendMaxBytes) {
      if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
      _dc!.send(RTCDataChannelMessage.fromBinary(bytes));
      return;
    }

    var offset = 0;
    final cap = _smallFileLegacyChunkBytes;
    final len = bytes.length;
    while (offset < len) {
      if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
      final end = math.min(offset + cap, len);
      _dc!.send(RTCDataChannelMessage.fromBinary(bytes.sublist(offset, end)));
      offset = end;
      while ((_dc?.bufferedAmount ?? 0) > cap * 24) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
  }

  Future<void> _onDownloadStart(Map<String, dynamic> msg) async {
    if (_currentShareCode == null) return;

    var resumeFrom = 0;
    final rf = msg['resumeFrom'];
    if (rf is int) {
      resumeFrom = rf;
    } else if (rf is num) {
      resumeFrom = rf.toInt();
    }

    final info = _shareService.getShareMeta(_currentShareCode!);
    if (info == null) {
      _sendJson({'type': 'error', 'code': 'NOT_FOUND', 'message': '分享不存在'});
      return;
    }

    if (info.hasPassword && !_passwordVerified) {
      _sendJson({
        'type': 'error',
        'code': 'AUTH_REQUIRED',
        'message': '需要密码验证',
      });
      return;
    }

    final storageDir = _storageDir;
    if (storageDir.isEmpty) {
      _sendJson({'type': 'error', 'code': 'NO_STORAGE', 'message': '存储目录未设置'});
      return;
    }

    final filePath = p.join(storageDir, info.path);
    final file = File(filePath);

    if (!await file.exists()) {
      _sendJson({
        'type': 'error',
        'code': 'FILE_NOT_FOUND',
        'message': '文件不存在',
      });
      return;
    }

    final fileSize = await file.length();
    if (resumeFrom < 0) resumeFrom = 0;
    if (resumeFrom > fileSize) resumeFrom = fileSize;

    final useSmallFileFastPath =
        resumeFrom == 0 && fileSize <= _smallFileFastPathMaxBytes;

    _sendJson({
      'type': 'file-meta',
      'fileName': info.fileName,
      'fileSize': fileSize,
      if (!useSmallFileFastPath) 'chunkPrefixBytes': 8,
      'resumeFrom': useSmallFileFastPath ? 0 : resumeFrom,
    });

    if (resumeFrom == fileSize) {
      _sendJson({'type': 'file-done'});
      return;
    }

    if (useSmallFileFastPath) {
      final bytes = await file.readAsBytes();
      await _sendSmallFileFastPath(bytes);
      if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
        _sendJson({'type': 'file-done'});
      }
      return;
    }

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      await raf.setPosition(resumeFrom);
      var pos = resumeFrom;
      final chunkCap = _dataChunkSize;

      while (pos < fileSize) {
        if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;

        final toRead = math.min(chunkCap, fileSize - pos);
        final payload = await raf.read(toRead);
        if (payload.isEmpty) break;

        final packet = _encodeOffsetPrefixedChunk(pos, payload);
        _dc!.send(RTCDataChannelMessage.fromBinary(packet));
        pos += payload.length;

        while ((_dc?.bufferedAmount ?? 0) > chunkCap * 24) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }
    } finally {
      await raf?.close();
    }

    if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _sendJson({'type': 'file-done'});
    }
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dc!.send(RTCDataChannelMessage(jsonEncode(data)));
    }
  }

  Future<void> dispose() async {
    _dc?.close();
    await _pc?.close();
    _dc = null;
    _pc = null;
  }
}
