import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/ffmpeg_bundle.dart';
import '../../../core/utils/ffmpeg_runner.dart';
import '../../../services/local_storage_service.dart';
import '../../cloud/cloud_storage_prefs.dart';
import '../../share/services/share_service.dart';
import 'share_p2p/ffmpeg_capabilities.dart';
import 'share_p2p/file_download_sender.dart';
import 'share_p2p/p2p_constants.dart';
import 'share_p2p/p2p_download_log.dart';
import 'share_p2p/stream_pipeline.dart';
import 'share_p2p/stream_probe.dart';
import 'video_stream_plan.dart';

/// 分享页（share-page-app）经 WebRTC DataChannel 从本机「网盘」拉流/下载；
/// 协议与分片细节见 `share_p2p/` 下各模块。
class ShareP2PHandler {
  ShareP2PHandler({
    required this.sendSignaling,
    this.onSessionEnded,
    required this.iceServers,
  });

  final void Function(Map<String, dynamic> message) sendSignaling;
  void Function()? onSessionEnded;
  final List<Map<String, dynamic>> iceServers;

  final ShareService _shareService = ShareService();
  final ShareP2pFfmpegCapabilities _ffmpegCaps = ShareP2pFfmpegCapabilities();

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  final List<Map<String, dynamic>> _pendingCandidates = [];

  String? _currentShareCode;
  bool _passwordVerified = false;
  bool _initialized = false;
  bool _disposeRequested = false;

  Completer<void>? _streamFlowGate;
  Completer<void>? _downloadFlowGate;
  Completer<void>? _downloadAckCompleter;

  int _streamPeerAckUpToSeq = 0;
  Completer<void>? _streamAckSeqCompleter;
  int? _streamAckWaitMinSeq;

  Timer? _seekDebounceTimer;
  Timer? _sessionEndTimer;
  Map<String, dynamic>? _pendingSeekMsg;
  Future<void> _offerQueue = Future.value();

  Process? _activeStreamProc;
  String? _activeStreamFile;
  String? _activeStreamFfmpeg;
  VideoStreamPlan? _activeStreamPlan;
  int _streamGeneration = 0;

  String get _storageDir =>
      LocalStorageService.instance.get<String>(kCloudStorageDirKey) ?? '';

  void _releaseStreamAckWait() {
    final c = _streamAckSeqCompleter;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    _streamAckSeqCompleter = null;
    _streamAckWaitMinSeq = null;
  }

  void _applyStreamPeerAck(dynamic upToSeqRaw) {
    if (upToSeqRaw == null) {
      _releaseStreamAckWait();
      return;
    }
    final v = upToSeqRaw is int
        ? upToSeqRaw
        : (upToSeqRaw is num ? upToSeqRaw.toInt() : null);
    if (v == null || v < 0) {
      _releaseStreamAckWait();
      return;
    }
    if (v > _streamPeerAckUpToSeq) {
      _streamPeerAckUpToSeq = v;
    }
    final wait = _streamAckWaitMinSeq;
    final c = _streamAckSeqCompleter;
    if (wait != null &&
        c != null &&
        !c.isCompleted &&
        _streamPeerAckUpToSeq >= wait) {
      c.complete();
      _streamAckSeqCompleter = null;
      _streamAckWaitMinSeq = null;
    }
  }

  void _releaseIdenticalStreamFlowGate(Completer<void> gate) {
    if (identical(_streamFlowGate, gate)) {
      try {
        if (!gate.isCompleted) gate.complete();
      } catch (_) {}
      _streamFlowGate = null;
    }
  }

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await _shareService.init();
      _initialized = true;
    }
  }

  Future<void> handleOffer(Map<String, dynamic> data) {
    final next = _offerQueue.then((_) => _handleOfferLocked(data));
    _offerQueue = next.catchError((_) {});
    return next;
  }

  Future<void> _handleOfferLocked(Map<String, dynamic> data) async {
    if (_disposeRequested) return;
    await _ensureInit();

    if (_pc != null) {
      shareP2pDownloadLog(
        'handleOffer: closing existing PC (re-offer on same handler)',
      );
      final oldPc = _pc;
      final oldDc = _dc;
      _pc = null;
      _dc = null;
      _pendingCandidates.clear();

      _killActiveStream(reason: 're-offer on same handler');
      _downloadFlowGate = null;
      _streamFlowGate = null;
      if (_downloadAckCompleter != null &&
          !_downloadAckCompleter!.isCompleted) {
        _downloadAckCompleter!.complete();
      }
      _downloadAckCompleter = null;
      _releaseStreamAckWait();
      _sessionEndTimer?.cancel();
      _sessionEndTimer = null;

      try {
        oldPc?.onConnectionState = null;
        oldPc?.onIceCandidate = null;
        oldPc?.onDataChannel = null;
      } catch (_) {}
      try {
        oldDc?.onDataChannelState = null;
        oldDc?.onMessage = null;
      } catch (_) {}
      try {
        oldDc?.close();
      } catch (_) {}
      try {
        await oldPc?.close();
      } catch (_) {}
    }

    if (_disposeRequested) return;

    final pc = await createPeerConnection({'iceServers': iceServers});
    if (_disposeRequested) {
      try {
        await pc.close();
      } catch (_) {}
      return;
    }
    _pc = pc;

    pc.onConnectionState = (RTCPeerConnectionState state) {
      if (_disposeRequested) return;
      if (!identical(_pc, pc)) return;
      shareP2pDownloadLog('pc connectionState=$state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        _sessionEndTimer?.cancel();
        _sessionEndTimer = null;
        return;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _sessionEndTimer?.cancel();
        _sessionEndTimer = Timer(const Duration(seconds: 5), () {
          _sessionEndTimer = null;
          if (_disposeRequested) return;
          if (!identical(_pc, pc)) return;
          if (_pc?.connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
            onSessionEnded?.call();
          }
        });
        return;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onSessionEnded?.call();
      }
    };

    pc.onIceCandidate = (candidate) {
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

    pc.onDataChannel = (channel) {
      if (!identical(_pc, pc)) {
        try {
          channel.close();
        } catch (_) {}
        return;
      }
      _dc = channel;
      _setupDataChannel();
    };

    await pc.setRemoteDescription(
      RTCSessionDescription(
        data['sdp'] as String?,
        data['type'] as String? ?? 'offer',
      ),
    );
    if (_disposeRequested || !identical(_pc, pc)) return;

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    if (_disposeRequested || !identical(_pc, pc)) return;

    sendSignaling({
      'type': 'answer',
      'data': {'sdp': answer.sdp, 'type': answer.type},
    });

    for (final c in _pendingCandidates) {
      try {
        await pc.addCandidate(
          RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            c['sdpMLineIndex'] as int?,
          ),
        );
      } catch (_) {}
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
    } catch (_) {}
  }

  void _setupDataChannel() {
    _dc!.onDataChannelState = (RTCDataChannelState state) {
      shareP2pDownloadLog('dc state=$state');
    };
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
      case 'stream-start':
        unawaited(_onStreamStart(msg));
        break;
      case 'stream-seek':
        _seekDebounceTimer?.cancel();
        _pendingSeekMsg = msg;
        _seekDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          final m = _pendingSeekMsg;
          _pendingSeekMsg = null;
          _seekDebounceTimer = null;
          if (m != null) unawaited(_onStreamSeek(m));
        });
        break;
      case 'stream-pause':
        if (_streamFlowGate == null || _streamFlowGate!.isCompleted) {
          _streamFlowGate = Completer<void>();
        }
        break;
      case 'stream-resume':
        if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
          _streamFlowGate!.complete();
        }
        _streamFlowGate = null;
        break;
      case 'stream-stop':
        _onStreamStop(msg);
        break;
      case 'download-pause':
        shareP2pDownloadLog(
          'rx download-pause (gateWas=${_downloadFlowGate == null ? "null" : (_downloadFlowGate!.isCompleted ? "done" : "waiting")})',
        );
        if (_downloadFlowGate == null || _downloadFlowGate!.isCompleted) {
          _downloadFlowGate = Completer<void>();
        }
        break;
      case 'download-resume':
        shareP2pDownloadLog('rx download-resume');
        if (_downloadFlowGate != null && !_downloadFlowGate!.isCompleted) {
          _downloadFlowGate!.complete();
        }
        _downloadFlowGate = null;
        break;
      case 'download-ack':
        shareP2pDownloadLog('rx download-ack');
        final ack = _downloadAckCompleter;
        if (ack != null && !ack.isCompleted) {
          ack.complete();
        }
        _downloadAckCompleter = null;
        break;
      case 'stream-data-ack':
        _applyStreamPeerAck(msg['upToSeq']);
        break;
    }
  }

  Future<void> _awaitDownloadAck() async {
    shareP2pDownloadLog('await download-ack');
    final c = Completer<void>();
    _downloadAckCompleter = c;
    try {
      await c.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('download-ack'),
      );
    } finally {
      if (identical(_downloadAckCompleter, c)) {
        _downloadAckCompleter = null;
      }
    }
  }

  Future<void> _awaitStreamDataAck(int minWireSeq) async {
    if (_streamPeerAckUpToSeq >= minWireSeq) return;
    final c = Completer<void>();
    _streamAckSeqCompleter = c;
    _streamAckWaitMinSeq = minWireSeq;
    if (_streamPeerAckUpToSeq >= minWireSeq) {
      if (!c.isCompleted) c.complete();
      _streamAckSeqCompleter = null;
      _streamAckWaitMinSeq = null;
      return;
    }
    try {
      await c.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('stream-data-ack'),
      );
    } finally {
      if (identical(_streamAckSeqCompleter, c)) {
        _streamAckSeqCompleter = null;
        _streamAckWaitMinSeq = null;
      }
    }
  }

  Future<void> _onStreamStart(Map<String, dynamic> msg) async {
    if (_currentShareCode == null) return;
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
    if (!FfmpegBundle.isSupportedPlatform) {
      _sendJson({
        'type': 'error',
        'code': 'UNSUPPORTED',
        'message': '当前设备不支持在线播放',
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

    final bins = await FfmpegBundle.ensureExtracted();
    final probe = await probeShareVideoStream(bins.ffprobePath, filePath);
    final plan = VideoStreamPlanner.plan(probe);

    // ignore: avoid_print
    print(
      '[ShareP2P] stream probe: vCodec=${probe.videoCodec} '
      'aCodec=${probe.audioCodec} '
      'size=${probe.width ?? "?"}x${probe.height ?? "?"} '
      'duration=${probe.duration} '
      'plan=${plan.describe()}',
    );

    if (plan.needsTranscode) {
      final transcodeEnabled =
          LocalStorageService.instance.get<bool>(
            StorageKeys.videoTranscodeStream,
          ) ??
          true;
      if (!transcodeEnabled) {
        _sendJson({
          'type': 'error',
          'code': 'UNSUPPORTED_CODEC',
          'message': '该视频编码不支持在线播放，请点击“下载”后用本地播放器打开',
        });
        return;
      }
      final transcodeSupported =
          await _ffmpegCaps.ensureLibx264Supported(bins.ffmpegPath);
      if (!transcodeSupported) {
        _sendJson({
          'type': 'error',
          'code': 'TRANSCODE_UNAVAILABLE',
          'message':
              '当前设备内置 ffmpeg 未包含 libx264，无法转码播放该视频，请更新 ffmpeg 产物或下载后本地播放',
        });
        return;
      }
    }

    double? resumeFrom;
    final rf = msg['resumeFrom'];
    if (rf is num) {
      final v = rf.toDouble();
      if (v.isFinite && v > 0) {
        final dur = probe.duration;
        if (dur != null && dur > 0 && v >= dur) {
          resumeFrom = null;
        } else {
          resumeFrom = v;
        }
      }
    }

    _streamGeneration++;
    _killActiveStream(reason: 'stream-start');
    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;
    _releaseStreamAckWait();
    _streamPeerAckUpToSeq = 0;

    _sendJson({
      'type': 'stream-meta',
      'mime': plan.mime,
      'codecs': plan.codecParts.join(', '),
      if (probe.duration != null) 'duration': probe.duration,
      if (probe.width != null) 'width': probe.width,
      if (probe.height != null) 'height': probe.height,
      if (resumeFrom != null) 'resume': true,
      if (resumeFrom != null) 'actualTime': resumeFrom,
      'binaryMode': 'init-segment-v2',
    });

    _activeStreamPlan = plan;
    if (resumeFrom != null) {
      // ignore: avoid_print
      print(
        '[ShareP2P] stream-start with resumeFrom=$resumeFrom '
        '(plan=${plan.describe()})',
      );
    }
    await _runStreamPipeline(
      bins.ffmpegPath,
      filePath,
      plan: plan,
      seekTime: resumeFrom,
    );
  }

  Future<void> _runStreamPipeline(
    String ffmpegPath,
    String filePath, {
    required VideoStreamPlan plan,
    double? seekTime,
  }) async {
    final gen = _streamGeneration;
    _activeStreamFile = filePath;
    _activeStreamFfmpeg = ffmpegPath;
    await runShareP2pStreamPipeline(
      ShareP2pStreamPipelineBindings(
        generation: gen,
        generationStillCurrent: () => _streamGeneration == gen,
        disposeRequested: () => _disposeRequested,
        peerConnection: () => _pc,
        dataChannel: () => _dc,
        streamFlowGate: () => _streamFlowGate,
        releaseIdenticalStreamFlowGate: _releaseIdenticalStreamFlowGate,
        sendJson: _sendJson,
        setActiveStreamProcess: (p) => _activeStreamProc = p,
        awaitStreamDataAck: _awaitStreamDataAck,
        queryPipeSupported: () =>
            _ffmpegCaps.ensurePipeProtocolSupported(ffmpegPath),
      ),
      ffmpegPath,
      filePath,
      plan: plan,
      seekTime: seekTime,
    );
  }

  void _killActiveStream({String? reason}) {
    final proc = _activeStreamProc;
    if (proc != null) {
      // ignore: avoid_print
      print(
        '[ShareP2P] killing active ffmpeg'
        '${reason != null ? " (reason=$reason)" : ""}'
        ' pid=${proc.pid}',
      );
    }
    try {
      _activeStreamProc?.kill(ProcessSignal.sigkill);
    } catch (_) {}
    _activeStreamProc = null;
  }

  void _onStreamStop(Map<String, dynamic> msg) {
    final reason = msg['reason'] as String? ?? 'unknown';
    // ignore: avoid_print
    print('[ShareP2P] rx stream-stop reason=$reason');

    _streamGeneration++;
    _killActiveStream(reason: 'stream-stop:$reason');

    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;
    _releaseStreamAckWait();
  }

  Future<void> _onStreamSeek(Map<String, dynamic> msg) async {
    final targetTime = (msg['targetTime'] as num?)?.toDouble() ?? 0.0;
    final ffmpegPath = _activeStreamFfmpeg;
    final path = _activeStreamFile;
    final plan = _activeStreamPlan;
    if (ffmpegPath == null || path == null || plan == null) return;

    _streamGeneration++;
    _killActiveStream(reason: 'stream-seek');

    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;
    _releaseStreamAckWait();
    _streamPeerAckUpToSeq = 0;

    await Future.delayed(Duration.zero);

    _sendJson({'type': 'stream-seeked', 'actualTime': targetTime});

    await _runStreamPipeline(
      ffmpegPath,
      path,
      plan: plan,
      seekTime: targetTime,
    );
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

  Future<void> _onDownloadStart(Map<String, dynamic> msg) async {
    if (_currentShareCode == null) return;

    if (_downloadFlowGate != null && !_downloadFlowGate!.isCompleted) {
      _downloadFlowGate!.complete();
    }
    _downloadFlowGate = null;
    if (_downloadAckCompleter != null && !_downloadAckCompleter!.isCompleted) {
      _downloadAckCompleter!.complete();
    }
    _downloadAckCompleter = null;

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

    var filePath = p.join(storageDir, info.path);
    var fileName = info.fileName;
    var file = File(filePath);

    if (!await file.exists()) {
      _sendJson({
        'type': 'error',
        'code': 'FILE_NOT_FOUND',
        'message': '文件不存在',
      });
      return;
    }

    final remux = msg['remuxFmp4'] == true;
    if (remux) {
      try {
        final outName = '${p.basenameWithoutExtension(fileName)}.mp4';
        final out = await FfmpegRunner().remuxToFragmentedMp4(
          inputPath: filePath,
          outputFileName: outName,
        );
        filePath = out.path;
        fileName = outName;
        file = File(filePath);
        resumeFrom = 0;
      } catch (_) {}
    }

    final fileSize = await file.length();
    if (resumeFrom < 0) resumeFrom = 0;
    if (resumeFrom > fileSize) resumeFrom = fileSize;

    final useSmallFileFastPath =
        resumeFrom == 0 && fileSize <= shareP2pSmallFileFastPathMaxBytes;

    _sendJson({
      'type': 'file-meta',
      'fileName': fileName,
      'fileSize': fileSize,
      if (!useSmallFileFastPath) 'chunkPrefixBytes': 8,
      'resumeFrom': useSmallFileFastPath ? 0 : resumeFrom,
    });

    if (resumeFrom == fileSize) {
      _sendJson({'type': 'file-done'});
      return;
    }

    final dlBindings = ShareP2pDownloadSendBindings(
      dc: () => _dc,
      awaitDownloadAck: _awaitDownloadAck,
      downloadFlowGate: () => _downloadFlowGate,
    );

    if (useSmallFileFastPath) {
      shareP2pDownloadLog(
        'small-file path size=$fileSize bytes (≤${shareP2pSmallFileFastPathMaxBytes ~/ (1024 * 1024)}MB cap)',
      );
      final bytes = await file.readAsBytes();
      await sendShareP2pSmallFileFastPath(dlBindings, bytes);
      if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
        shareP2pDownloadLog('small-file sent → file-done');
        _sendJson({'type': 'file-done'});
      } else {
        shareP2pDownloadLog(
          'small-file abort: dc closed before file-done state=${_dc?.state}',
        );
      }
      return;
    }

    shareP2pDownloadLog(
      'chunked path fileSize=$fileSize resumeFrom=$resumeFrom chunkCap=$shareP2pDataChunkSize',
    );

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      await raf.setPosition(resumeFrom);
      await runShareP2pChunkedDownloadFromRaf(
        b: dlBindings,
        raf: raf,
        fileSize: fileSize,
        startPos: resumeFrom,
        chunkCap: shareP2pDataChunkSize,
      );
    } finally {
      await raf?.close();
    }

    if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
      shareP2pDownloadLog('send loop finished → file-done (fileSize=$fileSize)');
      _sendJson({'type': 'file-done'});
    } else {
      shareP2pDownloadLog(
        'skip file-done: dc not open state=${_dc?.state} (sent may be incomplete)',
      );
    }
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dc!.send(RTCDataChannelMessage(jsonEncode(data)));
    }
  }

  Future<void> dispose() async {
    if (_disposeRequested) return;
    _disposeRequested = true;
    onSessionEnded = null;
    _sessionEndTimer?.cancel();
    _sessionEndTimer = null;
    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = null;
    _killActiveStream(reason: 'dispose');
    _activeStreamPlan = null;
    if (_downloadAckCompleter != null && !_downloadAckCompleter!.isCompleted) {
      _downloadAckCompleter!.complete();
    }
    _downloadAckCompleter = null;
    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;
    _releaseStreamAckWait();
    if (_downloadFlowGate != null && !_downloadFlowGate!.isCompleted) {
      _downloadFlowGate!.complete();
    }
    _downloadFlowGate = null;
    final pc = _pc;
    final dc = _dc;
    _pc = null;
    _dc = null;
    try {
      dc?.onDataChannelState = null;
      dc?.onMessage = null;
    } catch (_) {}
    try {
      pc?.onConnectionState = null;
      pc?.onIceCandidate = null;
      pc?.onDataChannel = null;
    } catch (_) {}
    try {
      dc?.close();
    } catch (_) {}
    try {
      await pc?.close();
    } catch (_) {}
  }
}
