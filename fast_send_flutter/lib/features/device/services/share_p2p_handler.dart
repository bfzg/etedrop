import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path/path.dart' as p;

import '../../../services/local_storage_service.dart';
import '../../share/services/share_service.dart';

const _storageDirKey = 'cloud_storage_dir';
const _chunkSize = 16384; // 16KB per DataChannel message

/// 处理浏览器通过 WebRTC P2P 请求分享文件的下载
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
      LocalStorageService.instance.get<String>(_storageDirKey) ?? '';

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
      'data': {
        'sdp': answer.sdp,
        'type': answer.type,
      },
    });

    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(RTCIceCandidate(
        c['candidate'] as String?,
        c['sdpMid'] as String?,
        c['sdpMLineIndex'] as int?,
      ));
    }
    _pendingCandidates.clear();
  }

  Future<void> handleIceCandidate(Map<String, dynamic> data) async {
    if (_pc == null) {
      _pendingCandidates.add(data);
      return;
    }
    try {
      await _pc!.addCandidate(RTCIceCandidate(
        data['candidate'] as String?,
        data['sdpMid'] as String?,
        data['sdpMLineIndex'] as int?,
      ));
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
        _onDownloadStart();
        break;
    }
  }

  void _onShareRequest(String shareCode) {
    _currentShareCode = shareCode;
    _passwordVerified = false;

    final info = _shareService.getShareMeta(shareCode);
    if (info == null) {
      _sendJson({
        'type': 'error',
        'code': 'NOT_FOUND',
        'message': '分享不存在或已过期',
      });
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
    final valid =
        _shareService.verifySharePassword(_currentShareCode!, password);
    _passwordVerified = valid;
    _sendJson({
      'type': 'verify-result',
      'success': valid,
      if (!valid) 'error': '密码错误',
    });
  }

  Future<void> _onDownloadStart() async {
    if (_currentShareCode == null) return;

    final info = _shareService.getShareMeta(_currentShareCode!);
    if (info == null) {
      _sendJson({
        'type': 'error',
        'code': 'NOT_FOUND',
        'message': '分享不存在',
      });
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
      _sendJson({
        'type': 'error',
        'code': 'NO_STORAGE',
        'message': '存储目录未设置',
      });
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
    _sendJson({
      'type': 'file-meta',
      'fileName': info.fileName,
      'fileSize': fileSize,
    });

    final bytes = await file.readAsBytes();
    for (int offset = 0; offset < bytes.length; offset += _chunkSize) {
      if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;

      final end = (offset + _chunkSize > bytes.length)
          ? bytes.length
          : offset + _chunkSize;
      _dc!.send(RTCDataChannelMessage.fromBinary(bytes.sublist(offset, end)));

      while ((_dc?.bufferedAmount ?? 0) > _chunkSize * 16) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    _sendJson({'type': 'file-done'});
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
