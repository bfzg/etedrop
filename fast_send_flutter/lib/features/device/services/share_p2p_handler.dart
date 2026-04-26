import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path/path.dart' as p;

import '../../../core/config/constants.dart';
import '../../../core/utils/ffmpeg_runner.dart';
import '../../../core/utils/ffmpeg_bundle.dart';
import '../../../services/local_storage_service.dart';
import '../../cloud/cloud_storage_prefs.dart';
import '../../share/services/share_service.dart';
import 'video_stream_plan.dart';

/// 单帧二进制负载（不含 8 字节偏移头），与 AppConstants.defaultBlockSize 对齐便于维护。
int get _dataChunkSize => AppConstants.defaultBlockSize;

/// 从头下载且不超过此大小时走「无偏移头」快速路径（一次读入 + 更少帧），避免每包 8 字节头与 RAF 循环开销。
/// 阈值不宜过大：超过后走带 `download-ack` 的分片路径，避免大文件在网页 legacy 模式堆满内存或 SCTP 背压导致 DC 提前关闭。
const int _smallFileFastPathMaxBytes = 4 * 1024 * 1024; // 4MB

/// 小文件尝试单帧发送的上限（超过则改为无头多分片，避开部分环境 DataChannel 单帧上限）。
const int _smallFileSingleSendMaxBytes = 128 * 1024;

/// 快速路径下无头分片的负载大小（可略大于带前缀路径）。
const int _smallFileLegacyChunkBytes = 64 * 1024;

/// 分片下载时发送侧 `bufferedAmount` 超过此值则等待再发下一包（SCTP/DC 背压，**应用层窗口无关**）。
/// 默认 4MB；与下方 ack 窗口是两层逻辑：4 与 8 不会「冲突」，只是分别约束「待发缓冲」和「发满多少再等 ack」。
const int _downloadMaxBufferedBytes = int.fromEnvironment(
  'SHARE_DOWNLOAD_MAX_BUFFERED_BYTES',
  defaultValue: 4 * 1024 * 1024,
);

/// 与 share-page-app `DOWNLOAD_ACK_WINDOW_BYTES` 一致：网页**落盘**满此量 payload 后才发 `download-ack`，发送端在此之前会 `await`。
/// 默认 4MB（原 8MB 时易出现：发送端已发满窗口、UI 仍显示较小已下载 → 长时间卡在 await，属预期）。
/// 编译覆盖：`--dart-define=SHARE_DOWNLOAD_ACK_WINDOW_BYTES=8388608`（8MB）等。
const int _downloadAckWindowBytes = int.fromEnvironment(
  'SHARE_DOWNLOAD_ACK_WINDOW_BYTES',
  defaultValue: 4 * 1024 * 1024,
);

/// 分享下载诊断日志：debug 默认开；release 排查时加 `--dart-define=SHARE_P2P_DL_LOG=true`
bool get _shareDownloadDiagEnabled =>
    kDebugMode ||
    const bool.fromEnvironment('SHARE_P2P_DL_LOG', defaultValue: false);

void _shareDownloadLog(String message) {
  if (!_shareDownloadDiagEnabled) return;
  debugPrint('[ShareP2P][download] $message');
}

/// 分享页（share-page-app）经 WebRTC DataChannel 从本机「网盘」存储目录拉取文件；
/// 小文件可走无头快速路径；大文件或断点续传走 8 字节偏移前缀分片（与 share-page-app 一致）。
class ShareP2PHandler {
  final void Function(Map<String, dynamic> message) sendSignaling;

  /// P2P 断开时通知 [DeviceManager] 从多会话表中移除（避免仅依赖 dispose）
  void Function()? onSessionEnded;

  /// 与当前服务器线路一致（见 [AppConstants.pubIceServersForRegion]）。
  final List<Map<String, dynamic>> iceServers;
  final ShareService _shareService = ShareService();

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  final List<Map<String, dynamic>> _pendingCandidates = [];

  String? _currentShareCode;
  bool _passwordVerified = false;
  bool _initialized = false;
  bool _disposeRequested = false;

  /// Flow control: the web client can pause/resume the stream to avoid
  /// overwhelming its SourceBuffer / JS memory queue.
  Completer<void>? _streamFlowGate;
  Completer<void>? _downloadFlowGate;

  /// 应用层窗口：网页确认已落盘 `download-ack` 后再继续发送（与 StreamSaver/SW 路径配合，避免 SCTP 撑爆）。
  Completer<void>? _downloadAckCompleter;

  /// Debounce rapid seek requests — only act on the latest one.
  Timer? _seekDebounceTimer;
  Timer? _sessionEndTimer;
  Map<String, dynamic>? _pendingSeekMsg;

  /// 上一次 [handleOffer] 仍在进行（含异步等待）时，新的 offer 必须排队，
  /// 否则两次 handleOffer 会并行修改 [_pc] / [_dc] 引用，互相把对方刚建好的连接拆掉。
  Future<void> _offerQueue = Future.value();

  ShareP2PHandler({
    required this.sendSignaling,
    this.onSessionEnded,
    required this.iceServers,
  });

  String get _storageDir =>
      LocalStorageService.instance.get<String>(kCloudStorageDirKey) ?? '';

  Future<void> _ensureInit() async {
    if (!_initialized) {
      await _shareService.init();
      _initialized = true;
    }
  }

  Future<void> handleOffer(Map<String, dynamic> data) {
    // 串行化：浏览器在调试 / StrictMode / DC 抖动后会快速发出 2~3 次 offer，
    // 此处用 Future 队列保证一次只重建一个 PC，否则新旧 handleOffer 会互相覆盖
    // 对方刚 setLocal/setRemote 好的 SDP，最终导致 ICE 连接死掉。
    final next = _offerQueue.then((_) => _handleOfferLocked(data));
    _offerQueue = next.catchError((_) {});
    return next;
  }

  Future<void> _handleOfferLocked(Map<String, dynamic> data) async {
    if (_disposeRequested) return;
    await _ensureInit();

    // 同一 Handler 收到新的 offer：先把旧 PC/DC 的事件回调摘掉，再关闭。
    //
    // 历史上这里是 `_dc?.close(); await _pc?.close();`，旧 PC 关闭时会触发
    // onConnectionState=Closed → onSessionEnded → DeviceManager._removeP2pSession
    // → handler.dispose()。dispose 会把当前 handler 的 `_disposeRequested=true`，
    // 进而把我们正要建的“新 PC”一起关掉，并把 handler 从 `_p2pHandlers` 里移走，
    // 表现就是日志里观察到的「连接老是断开重连 + ffmpeg exited code=-9」。
    //
    // 解法：在关闭旧 PC 之前，先把旧 PC/DC 的所有回调置空，让“关闭旧连接”这件事
    // 不再触发本 handler 的 sessionEnded / dispose。
    if (_pc != null) {
      _shareDownloadLog(
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
      // 仅响应当前活跃 PC 的事件（如果之间又有新的 offer 把 _pc 替换掉了，
      // 这个回调就属于「上一代」PC，应当忽略）。
      if (!identical(_pc, pc)) return;
      _shareDownloadLog('pc connectionState=$state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        _sessionEndTimer?.cancel();
        _sessionEndTimer = null;
        return;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _sessionEndTimer?.cancel();
        // `disconnected` on macOS/WebRTC is often transient; ending the
        // session immediately can race a successful reconnection and crash
        // the native DataChannel bridge.
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
      // Late-arriving DC for an old PC after we replaced `_pc` → drop it.
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
    } catch (_) {
      // 连接已关闭或正在释放时，迟到的 ICE candidate 会报 peerConnection not found，忽略即可
    }
  }

  void _setupDataChannel() {
    _dc!.onDataChannelState = (RTCDataChannelState state) {
      _shareDownloadLog('dc state=$state');
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
        _shareDownloadLog(
          'rx download-pause (gateWas=${_downloadFlowGate == null ? "null" : (_downloadFlowGate!.isCompleted ? "done" : "waiting")})',
        );
        if (_downloadFlowGate == null || _downloadFlowGate!.isCompleted) {
          _downloadFlowGate = Completer<void>();
        }
        break;
      case 'download-resume':
        _shareDownloadLog('rx download-resume');
        if (_downloadFlowGate != null && !_downloadFlowGate!.isCompleted) {
          _downloadFlowGate!.complete();
        }
        _downloadFlowGate = null;
        break;
      case 'download-ack':
        _shareDownloadLog('rx download-ack');
        final ack = _downloadAckCompleter;
        if (ack != null && !ack.isCompleted) {
          ack.complete();
        }
        _downloadAckCompleter = null;
        break;
    }
  }

  Future<void> _awaitDownloadAck() async {
    _shareDownloadLog('await download-ack');
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
    final probe = await _probeStream(bins.ffprobePath, filePath);
    final plan = VideoStreamPlanner.plan(probe);

    print(
      '[ShareP2P] stream probe: vCodec=${probe.videoCodec} '
      'aCodec=${probe.audioCodec} '
      'size=${probe.width ?? "?"}x${probe.height ?? "?"} '
      'duration=${probe.duration} '
      'plan=${plan.describe()}',
    );

    if (plan.needsTranscode) {
      // 读取用户「视频在线转码」偏好（默认开启）
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
      final transcodeSupported = await _ffmpegSupportsH264Transcode(
        bins.ffmpegPath,
      );
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

    // Invalidate any previous pipeline and reset flow control.
    _streamGeneration++;
    _killActiveStream(reason: 'stream-start');
    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;

    _sendJson({
      'type': 'stream-meta',
      'mime': plan.mime,
      'codecs': plan.codecParts.join(', '),
      if (probe.duration != null) 'duration': probe.duration,
      if (probe.width != null) 'width': probe.width,
      if (probe.height != null) 'height': probe.height,
      'binaryMode': 'init-segment-v1',
    });

    _activeStreamPlan = plan;
    await _runStreamPipeline(bins.ffmpegPath, filePath, plan: plan);
  }

  Process? _activeStreamProc;
  String? _activeStreamFile;
  String? _activeStreamFfmpeg;
  VideoStreamPlan? _activeStreamPlan;
  bool? _ffmpegPipeSupported;
  bool? _ffmpegHasLibx264;

  /// Incremented on each new stream / seek; old pipelines check this and bail out.
  int _streamGeneration = 0;

  Future<bool> _ffmpegSupportsPipe(String ffmpegPath) async {
    if (_ffmpegPipeSupported != null) return _ffmpegPipeSupported!;
    try {
      final res = await Process.run(ffmpegPath, [
        '-protocols',
      ], stdoutEncoding: const SystemEncoding());
      final stdout = res.stdout as String;
      _ffmpegPipeSupported = stdout.contains('pipe');
    } catch (_) {
      _ffmpegPipeSupported = false;
    }
    print('[ShareP2P] ffmpeg pipe protocol supported: $_ffmpegPipeSupported');
    return _ffmpegPipeSupported!;
  }

  Future<bool> _ffmpegSupportsH264Transcode(String ffmpegPath) async {
    if (_ffmpegHasLibx264 != null) return _ffmpegHasLibx264!;
    try {
      final res = await Process.run(ffmpegPath, [
        '-encoders',
      ], stdoutEncoding: const SystemEncoding());
      final stdout = (res.stdout ?? '').toString();
      _ffmpegHasLibx264 = stdout.contains(' libx264 ');
    } catch (_) {
      _ffmpegHasLibx264 = false;
    }
    print('[ShareP2P] ffmpeg libx264 supported: $_ffmpegHasLibx264');
    return _ffmpegHasLibx264!;
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

    final usePipe = await _ffmpegSupportsPipe(ffmpegPath);
    final tempFile = usePipe
        ? null
        : File(
            p.join(
              Directory.systemTemp.path,
              'fastsend_stream_${DateTime.now().millisecondsSinceEpoch}.mp4',
            ),
          );

    final args = plan.buildFfmpegArgs(
      inputPath: filePath,
      usePipe: usePipe,
      tempOutputPath: tempFile?.path,
      seekTime: seekTime,
    );

    const int kBinInit = 0;
    const int kBinSeg = 1;

    Uint8List _wrapBin(int kind, Uint8List payload) {
      final out = Uint8List(1 + payload.length);
      out[0] = kind;
      out.setRange(1, out.length, payload);
      return out;
    }

    ({List<Uint8List> boxes, Uint8List rest}) _splitBoxes(Uint8List buf) {
      final boxes = <Uint8List>[];
      var off = 0;
      while (buf.length - off >= 8) {
        final bd = ByteData.sublistView(buf, off);
        final size32 = bd.getUint32(0, Endian.big);
        int header = 8;
        int? size;
        if (size32 == 0) break;
        if (size32 == 1) {
          if (buf.length - off < 16) break;
          final size64 = bd.getUint64(8, Endian.big);
          header = 16;
          if (size64 > 0x7fffffff) break;
          size = size64;
        } else {
          size = size32;
        }
        if (size < header) break;
        if (buf.length - off < size) break;
        boxes.add(buf.sublist(off, off + size));
        off += size;
      }
      return (boxes: boxes, rest: buf.sublist(off));
    }

    bool _isType(Uint8List box, String t) {
      if (box.length < 8) return false;
      final s = String.fromCharCodes(box.sublist(4, 8));
      return s == t;
    }

    var totalBytesSent = 0;
    try {
      print(
        '[ShareP2P] ffmpeg start (pipe=$usePipe): $ffmpegPath ${args.join(' ')}',
      );
      final proc = await Process.start(ffmpegPath, args);
      _activeStreamProc = proc;

      final stderrBuf = StringBuffer();
      proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((
        s,
      ) {
        stderrBuf.write(s);
      });

      var buf = Uint8List(0);
      var init = Uint8List(0);
      var sawMoov = false;
      var initSent = false;
      var pending = Uint8List(0);

      // PC 状态在底层断网时会先于 DC 状态变化（typically 数百毫秒甚至秒级滞后）。
      // 只看 DC.state 会让我们在 PC 已经 Disconnected 时继续往「死管道」里灌数据，
      // 直到对端彻底拆链；改为同时监控 PC，遇到 Failed/Closed 立刻收手，
      // Disconnected 给最多 ~5s 自愈窗口（与 _sessionEndTimer 一致）。
      bool isPcUnhealthyHard() {
        final s = _pc?.connectionState;
        return _pc == null ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
            s == RTCPeerConnectionState.RTCPeerConnectionStateFailed;
      }

      bool isPcDisconnected() {
        final s = _pc?.connectionState;
        return s ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected;
      }

      /// 等待 PC 从 Disconnected 自愈；超过 [maxWaitMs] 仍未恢复则视为掉线。
      /// 返回 true 表示恢复（或当前已不是 Disconnected），false 表示需要 bail。
      Future<bool> waitForPcRecovery({int maxWaitMs = 5000}) async {
        if (!isPcDisconnected()) return !isPcUnhealthyHard();
        print(
          '[ShareP2P] pc=Disconnected during stream — pausing send up to '
          '${maxWaitMs}ms (gen=$gen, sent=$totalBytesSent)',
        );
        final start = DateTime.now();
        while (isPcDisconnected()) {
          if (_streamGeneration != gen) return false;
          if (_disposeRequested) return false;
          if (DateTime.now().difference(start).inMilliseconds > maxWaitMs) {
            print(
              '[ShareP2P] pc still Disconnected after ${maxWaitMs}ms — abort '
              'pipeline (gen=$gen, sent=$totalBytesSent)',
            );
            return false;
          }
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (isPcUnhealthyHard()) return false;
        print(
          '[ShareP2P] pc recovered to ${_pc?.connectionState} '
          '(gen=$gen, sent=$totalBytesSent)',
        );
        return true;
      }

      Future<void> sendBin(int kind, Uint8List payload) async {
        if (_streamGeneration != gen) return;
        if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
        if (payload.isEmpty) return;
        // 单帧过大易超过 SCTP/WebRTC 协商上限，对端直接关 DC（表现为刚发完 init 就断）。
        // 60KB + 1 字节 kind 前缀在 flutter_webrtc ↔ 浏览器侧更稳妥。
        const maxChunk = 60 * 1024;
        var off = 0;
        var chunksSent = 0;
        while (off < payload.length) {
          if (_streamGeneration != gen) return;
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
          if (isPcUnhealthyHard()) return;
          if (isPcDisconnected()) {
            final ok = await waitForPcRecovery();
            if (!ok) return;
            if (_streamGeneration != gen) return;
            if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
          }
          final gate = _streamFlowGate;
          if (gate != null && !gate.isCompleted) {
            print(
              '[ShareP2P] flow-control: paused (gen=$gen, sent=$totalBytesSent)',
            );
            // 不裸 await gate.future：如果对端在 pause 期间崩了或者
            // stream-resume 被网络丢了，sender 会永远挂死。每 1s 醒一次
            // 检查 generation / DC / PC，全坏掉时主动退出，让 ffmpeg 走 SIGKILL。
            while (!gate.isCompleted) {
              await Future.any<void>([
                gate.future,
                Future<void>.delayed(const Duration(seconds: 1)),
              ]);
              if (_streamGeneration != gen) return;
              if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
              if (isPcUnhealthyHard()) return;
              if (gate.isCompleted) break;
              if (isPcDisconnected()) {
                final ok = await waitForPcRecovery();
                if (!ok) return;
              }
            }
            print('[ShareP2P] flow-control: resumed (gen=$gen)');
          }
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
          final end = math.min(off + maxChunk, payload.length);
          final slice = payload.sublist(off, end);
          _dc!.send(RTCDataChannelMessage.fromBinary(_wrapBin(kind, slice)));
          totalBytesSent += slice.length;
          off = end;
          chunksSent++;
          while ((_dc?.bufferedAmount ?? 0) > 1024 * 1024) {
            await Future.delayed(const Duration(milliseconds: 2));
          }
          if (chunksSent % 8 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
      }

      Future<void> processChunks(Stream<List<int>> source) async {
        await for (final chunk in source) {
          if (_streamGeneration != gen) return;
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen ||
              isPcUnhealthyHard()) {
            try {
              proc.kill(ProcessSignal.sigkill);
            } catch (_) {}
            return;
          }
          if (isPcDisconnected()) {
            final ok = await waitForPcRecovery();
            if (!ok) {
              try {
                proc.kill(ProcessSignal.sigkill);
              } catch (_) {}
              return;
            }
          }
          if (chunk.isEmpty) continue;
          final incoming = Uint8List.fromList(chunk);
          if (buf.isEmpty) {
            buf = incoming;
          } else {
            final merged = Uint8List(buf.length + incoming.length);
            merged.setRange(0, buf.length, buf);
            merged.setRange(buf.length, merged.length, incoming);
            buf = merged;
          }

          final split = _splitBoxes(buf);
          buf = split.rest;

          for (final box in split.boxes) {
            if (!initSent) {
              if (_isType(box, 'moov')) sawMoov = true;
              if (_isType(box, 'moof')) {
                if (!sawMoov) {
                  _sendJson({
                    'type': 'error',
                    'code': 'STREAM_INIT_INVALID',
                    'message': '视频在线播放初始化失败（缺少 moov）',
                  });
                  return;
                }
                print('[ShareP2P] sending init segment: ${init.length} bytes');
                await sendBin(kBinInit, init);
                initSent = true;
                init = Uint8List(0);
                pending = box;
                continue;
              }
              final merged = Uint8List(init.length + box.length);
              merged.setRange(0, init.length, init);
              merged.setRange(init.length, merged.length, box);
              init = merged;
              continue;
            }

            if (_isType(box, 'moof')) {
              await sendBin(kBinSeg, pending);
              pending = box;
            } else {
              final merged = Uint8List(pending.length + box.length);
              merged.setRange(0, pending.length, pending);
              merged.setRange(pending.length, merged.length, box);
              pending = merged;
            }
          }
        }
      }

      if (usePipe) {
        await processChunks(proc.stdout);
        final code = await proc.exitCode;
        _activeStreamProc = null;
        final stderr = stderrBuf.toString().trim();
        final brokenPipe =
            stderr.contains('Broken pipe') ||
            stderr.contains('error code: -32');
        final interrupted =
            _streamGeneration != gen ||
            _dc?.state != RTCDataChannelState.RTCDataChannelOpen;
        print('[ShareP2P] ffmpeg exited: code=$code');
        if (stderr.isNotEmpty) print('[ShareP2P] ffmpeg stderr: $stderr');
        if (code != 0) {
          if (interrupted || brokenPipe) {
            print(
              '[ShareP2P] ignore ffmpeg non-zero exit (interrupted=$interrupted, brokenPipe=$brokenPipe, gen=$gen, current=${_streamGeneration}, dc=${_dc?.state})',
            );
            return;
          }
          _sendJson({
            'type': 'error',
            'code': 'STREAM_TRANSCODE_FAILED',
            'message': '视频转码失败，当前设备内置 ffmpeg 可能缺少对应格式或编码支持',
          });
          return;
        }
        if (!initSent && pending.isEmpty && totalBytesSent == 0) {
          _sendJson({
            'type': 'error',
            'code': 'STREAM_EMPTY_OUTPUT',
            'message': '视频转码未产出可播放数据，请尝试下载后使用本地播放器打开',
          });
          return;
        }
      } else {
        final code = await proc.exitCode;
        _activeStreamProc = null;
        final stderr = stderrBuf.toString().trim();
        final brokenPipe =
            stderr.contains('Broken pipe') ||
            stderr.contains('error code: -32');
        final interrupted =
            _streamGeneration != gen ||
            _dc?.state != RTCDataChannelState.RTCDataChannelOpen;
        print('[ShareP2P] ffmpeg exited: code=$code');
        if (stderr.isNotEmpty) print('[ShareP2P] ffmpeg stderr: $stderr');
        if (code != 0 || !tempFile!.existsSync()) {
          if (code != 0 && (interrupted || brokenPipe)) {
            print(
              '[ShareP2P] ignore ffmpeg non-zero exit (interrupted=$interrupted, brokenPipe=$brokenPipe, gen=$gen, current=${_streamGeneration}, dc=${_dc?.state})',
            );
            return;
          }
          print('[ShareP2P] ffmpeg failed or no output file');
          return;
        }
        print('[ShareP2P] temp fMP4 size: ${tempFile.lengthSync()} bytes');
        await processChunks(tempFile.openRead());
      }

      if (_streamGeneration == gen && initSent && pending.isNotEmpty) {
        await sendBin(kBinSeg, pending);
      }
      print(
        '[ShareP2P] stream pipeline finished (gen=$gen, current=${_streamGeneration}, sent=$totalBytesSent)',
      );
    } finally {
      _activeStreamProc = null;
      if (tempFile != null) {
        try {
          if (tempFile.existsSync()) await tempFile.delete();
        } catch (_) {}
      }
    }

    if (_streamGeneration != gen) {
      print('[ShareP2P] stream gen=$gen cancelled, skipping stream-done');
      return;
    }
    if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
      print('[ShareP2P] sending stream-done (gen=$gen)');
      _sendJson({'type': 'stream-done'});
    } else {
      print(
        '[ShareP2P] skip stream-done (gen=$gen): dc state=${_dc?.state} (对端可能已断开)',
      );
    }
  }

  void _killActiveStream({String? reason}) {
    final proc = _activeStreamProc;
    if (proc != null) {
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
    print('[ShareP2P] rx stream-stop reason=$reason');

    _streamGeneration++;
    _killActiveStream(reason: 'stream-stop:$reason');

    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;
  }

  Future<void> _onStreamSeek(Map<String, dynamic> msg) async {
    final targetTime = (msg['targetTime'] as num?)?.toDouble() ?? 0.0;
    final ffmpegPath = _activeStreamFfmpeg;
    final filePath = _activeStreamFile;
    final plan = _activeStreamPlan;
    if (ffmpegPath == null || filePath == null || plan == null) return;

    // Invalidate old pipeline first so it stops sending.
    _streamGeneration++;
    _killActiveStream(reason: 'stream-seek');

    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;

    // Yield so the old pipeline's async loops notice the generation change and exit.
    await Future.delayed(Duration.zero);

    // 仅在转码模式下回传 actualTime 并设置 timestampOffset。
    // copy 模式下起始时间点可能对齐到关键帧，强行用 targetTime 容易导致
    // MSE 时间轴错位，表现为 seek 后卡住/不播。
    if (plan.needsTranscode) {
      _sendJson({'type': 'stream-seeked', 'actualTime': targetTime});
    } else {
      _sendJson({'type': 'stream-seeked'});
    }

    await _runStreamPipeline(
      ffmpegPath,
      filePath,
      plan: plan,
      seekTime: targetTime,
    );
  }

  Future<double?> _probeDuration(String ffprobePath, String inputPath) async {
    try {
      final res = await Process.run(ffprobePath, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=nw=1:nk=1',
        inputPath,
      ]);
      if (res.exitCode != 0) return null;
      final out = (res.stdout ?? '').toString().trim();
      if (out.isEmpty || out == 'N/A') return null;
      return double.tryParse(out.split(RegExp(r'\r?\n')).first.trim());
    } catch (_) {
      return null;
    }
  }

  Future<String?> _probeCodec(
    String ffprobePath,
    String inputPath, {
    required String streamSelector,
  }) async {
    try {
      final res = await Process.run(ffprobePath, [
        '-v',
        'error',
        '-select_streams',
        streamSelector,
        '-show_entries',
        'stream=codec_name',
        '-of',
        'default=nw=1:nk=1',
        inputPath,
      ]);
      if (res.exitCode != 0) return null;
      final out = (res.stdout ?? '').toString().trim();
      if (out.isEmpty) return null;
      return out.split(RegExp(r'\r?\n')).first.trim();
    } catch (_) {
      return null;
    }
  }

  Future<({int width, int height})?> _probeVideoSize(
    String ffprobePath,
    String inputPath,
  ) async {
    try {
      final res = await Process.run(ffprobePath, [
        '-v',
        'error',
        '-select_streams',
        'v:0',
        '-show_entries',
        'stream=width,height',
        '-of',
        'csv=p=0:s=x',
        inputPath,
      ]);
      if (res.exitCode != 0) return null;
      final out = (res.stdout ?? '').toString().trim();
      if (out.isEmpty) return null;
      final line = out.split(RegExp(r'\r?\n')).first.trim();
      final parts = line.split('x');
      if (parts.length != 2) return null;
      final w = int.tryParse(parts[0]);
      final h = int.tryParse(parts[1]);
      if (w == null || h == null || w <= 0 || h <= 0) return null;
      return (width: w, height: h);
    } catch (_) {
      return null;
    }
  }

  /// 一次性把所有 ffprobe 信息收齐，喂给 [VideoStreamPlanner.plan]。
  Future<VideoStreamProbe> _probeStream(
    String ffprobePath,
    String inputPath,
  ) async {
    final results = await Future.wait<Object?>([
      _probeCodec(ffprobePath, inputPath, streamSelector: 'v:0'),
      _probeCodec(ffprobePath, inputPath, streamSelector: 'a:0'),
      _probeDuration(ffprobePath, inputPath),
      _probeVideoSize(ffprobePath, inputPath),
    ]);
    final size = results[3] as ({int width, int height})?;
    return VideoStreamProbe(
      videoCodec: results[0] as String?,
      audioCodec: results[1] as String?,
      width: size?.width,
      height: size?.height,
      duration: results[2] as double?,
      fileExtensionLower: p
          .extension(inputPath)
          .toLowerCase()
          .replaceFirst('.', ''),
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
      while ((_dc?.bufferedAmount ?? 0) > _downloadMaxBufferedBytes) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
  }

  Future<void> _onDownloadStart(Map<String, dynamic> msg) async {
    if (_currentShareCode == null) return;

    // New transfer: drop any stale pause gate (e.g. lost download-resume on the web).
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

    // 可选：按需 remux 为浏览器/MSE 更友好的 fMP4（不转码，性能开销很低）。
    // 前端需显式请求，避免对所有文件默认增加一次磁盘 IO。
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
      } catch (_) {
        // remux 失败时降级为原文件直传
      }
    }

    final fileSize = await file.length();
    if (resumeFrom < 0) resumeFrom = 0;
    if (resumeFrom > fileSize) resumeFrom = fileSize;

    final useSmallFileFastPath =
        resumeFrom == 0 && fileSize <= _smallFileFastPathMaxBytes;

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

    if (useSmallFileFastPath) {
      _shareDownloadLog(
        'small-file path size=$fileSize bytes (≤${_smallFileFastPathMaxBytes ~/ (1024 * 1024)}MB cap)',
      );
      final bytes = await file.readAsBytes();
      await _sendSmallFileFastPath(bytes);
      if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
        _shareDownloadLog('small-file sent → file-done');
        _sendJson({'type': 'file-done'});
      } else {
        _shareDownloadLog(
          'small-file abort: dc closed before file-done state=${_dc?.state}',
        );
      }
      return;
    }

    _shareDownloadLog(
      'chunked path fileSize=$fileSize resumeFrom=$resumeFrom chunkCap=$_dataChunkSize',
    );

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      await raf.setPosition(resumeFrom);
      var pos = resumeFrom;
      final chunkCap = _dataChunkSize;
      var lastLogPos = pos;
      const logEveryBytes = 5 * 1024 * 1024;
      var sentSinceAck = 0;

      while (pos < fileSize) {
        if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
          _shareDownloadLog(
            'abort send loop: dc not open at pos=$pos/$fileSize state=${_dc?.state}',
          );
          return;
        }
        final gate = _downloadFlowGate;
        if (gate != null && !gate.isCompleted) {
          _shareDownloadLog(
            'await downloadFlowGate pos=$pos/$fileSize buffered=${_dc?.bufferedAmount ?? -1}',
          );
          await gate.future;
          _shareDownloadLog(
            'gate released pos=$pos/$fileSize buffered=${_dc?.bufferedAmount ?? -1}',
          );
        }
        if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
          _shareDownloadLog(
            'abort send loop after gate: dc not open at pos=$pos/$fileSize',
          );
          return;
        }

        final toRead = math.min(chunkCap, fileSize - pos);
        final payload = await raf.read(toRead);
        if (payload.isEmpty) break;

        final packet = _encodeOffsetPrefixedChunk(pos, payload);
        _dc!.send(RTCDataChannelMessage.fromBinary(packet));
        pos += payload.length;
        sentSinceAck += payload.length;

        var spin = 0;
        while ((_dc?.bufferedAmount ?? 0) > _downloadMaxBufferedBytes) {
          if (spin == 200) {
            _shareDownloadLog(
              'bufferedAmount spin ~1s pos=$pos/$fileSize buf=${_dc?.bufferedAmount}',
            );
          }
          spin++;
          await Future.delayed(const Duration(milliseconds: 5));
        }

        if (sentSinceAck >= _downloadAckWindowBytes) {
          try {
            await _awaitDownloadAck();
          } catch (e) {
            _shareDownloadLog('download-ack failed: $e');
            if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
              return;
            }
            rethrow;
          }
          sentSinceAck = 0;
        }

        if (pos - lastLogPos >= logEveryBytes || pos >= fileSize) {
          _shareDownloadLog(
            'progress pos=$pos/$fileSize buffered=${_dc?.bufferedAmount ?? -1}',
          );
          lastLogPos = pos;
        }
      }
      if (sentSinceAck > 0) {
        try {
          await _awaitDownloadAck();
        } catch (e) {
          _shareDownloadLog('final download-ack failed: $e');
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
            return;
          }
          rethrow;
        }
      }
    } finally {
      await raf?.close();
    }

    if (_dc?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _shareDownloadLog('send loop finished → file-done (fileSize=$fileSize)');
      _sendJson({'type': 'file-done'});
    } else {
      _shareDownloadLog(
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
