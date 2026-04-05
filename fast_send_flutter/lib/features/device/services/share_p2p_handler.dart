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

/// 单帧二进制负载（不含 8 字节偏移头），与 AppConstants.defaultBlockSize 对齐便于维护。
int get _dataChunkSize => AppConstants.defaultBlockSize;

/// 从头下载且不超过此大小时走「无偏移头」快速路径（一次读入 + 更少帧），避免每包 8 字节头与 RAF 循环开销。
/// 阈值不宜过大：超过后走带 `download-ack` 的分片路径，避免大文件在网页 legacy 模式堆满内存或 SCTP 背压导致 DC 提前关闭。
const int _smallFileFastPathMaxBytes = 4 * 1024 * 1024; // 4MB

/// 小文件尝试单帧发送的上限（超过则改为无头多分片，避开部分环境 DataChannel 单帧上限）。
const int _smallFileSingleSendMaxBytes = 128 * 1024;

/// 快速路径下无头分片的负载大小（可略大于带前缀路径）。
const int _smallFileLegacyChunkBytes = 64 * 1024;

/// 分片下载时发送侧 `bufferedAmount` 超过此值则等待再发下一包。
/// 对端走 StreamSaver+SW 等无真实背压路径时须保持较小，否则 SCTP 堆积易断连（原 `chunkCap*24` 约 786KB 仍偏大）。
const int _downloadMaxBufferedBytes = 256 * 1024;

/// 与 share-page-app `DOWNLOAD_ACK_WINDOW_BYTES` 一致：网页每落盘此量 payload 后回传 `download-ack`，发送端再发下一窗口。
const int _downloadAckWindowBytes = 512 * 1024;

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
  Map<String, dynamic>? _pendingSeekMsg;

  ShareP2PHandler({required this.sendSignaling, this.onSessionEnded});

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

    // 同一 Handler 不应收到第二次 offer；若发生则先关旧 PC（勿调 dispose，以免 _disposeRequested 阻断后续逻辑）
    if (_pc != null) {
      _shareDownloadLog('handleOffer: closing existing PC (re-offer on same handler)');
      _killActiveStream();
      _downloadFlowGate = null;
      _streamFlowGate = null;
      if (_downloadAckCompleter != null && !_downloadAckCompleter!.isCompleted) {
        _downloadAckCompleter!.complete();
      }
      _downloadAckCompleter = null;
      _dc?.close();
      await _pc?.close();
      _dc = null;
      _pc = null;
      _pendingCandidates.clear();
    }

    _pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    _pc!.onConnectionState = (RTCPeerConnectionState state) {
      if (_disposeRequested) return;
      _shareDownloadLog('pc connectionState=$state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onSessionEnded?.call();
      }
    };

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

    // 先做最小可播约束：仅允许 H.264（+ 可选 AAC）走在线播放，避免浏览器端 MSE 静默失败。
    // 未来可扩展为 stream-meta 携带 codec/mime 并在 web 端协商。
    final bins = await FfmpegBundle.ensureExtracted();
    final vCodec = await _probeCodec(
      bins.ffprobePath,
      filePath,
      streamSelector: 'v:0',
    );
    final aCodec = await _probeCodec(
      bins.ffprobePath,
      filePath,
      streamSelector: 'a:0',
    );
    final vOk = vCodec == null || vCodec == 'h264' || vCodec == 'hevc';
    final aOk = aCodec == null || aCodec == 'aac';
    if (!vOk || !aOk) {
      _sendJson({
        'type': 'error',
        'code': 'UNSUPPORTED_CODEC',
        'message': '该视频编码不支持在线播放，请点击“下载”后用本地播放器打开',
      });
      return;
    }

    final duration = await _probeDuration(bins.ffprobePath, filePath);

    print(
      '[ShareP2P] stream probe: vCodec=$vCodec aCodec=$aCodec duration=$duration',
    );

    final videoCodecStr = vCodec == 'hevc' ? 'hev1.1.6.L93.B0' : 'avc1.42E01E';
    final codecParts = <String>[videoCodecStr];
    if (aCodec == 'aac') codecParts.add('mp4a.40.2');
    final mime = 'video/mp4; codecs="${codecParts.join(', ')}"';

    // Invalidate any previous pipeline and reset flow control.
    _streamGeneration++;
    _killActiveStream();
    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;

    _sendJson({
      'type': 'stream-meta',
      'mime': mime,
      'codecs': codecParts.join(', '),
      if (duration != null) 'duration': duration,
      'binaryMode': 'init-segment-v1',
    });

    await _runStreamPipeline(bins.ffmpegPath, filePath);
  }

  Process? _activeStreamProc;
  String? _activeStreamFile;
  String? _activeStreamFfmpeg;
  bool? _ffmpegPipeSupported;

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

  Future<void> _runStreamPipeline(
    String ffmpegPath,
    String filePath, {
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

    final args = <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      if (seekTime != null) ...['-ss', seekTime.toStringAsFixed(3)],
      '-i',
      filePath,
      '-map',
      '0',
      '-c',
      'copy',
      '-movflags',
      '+frag_keyframe+empty_moov+default_base_moof',
      '-f',
      'mp4',
      if (usePipe) 'pipe:1' else ...['-y', tempFile!.path],
    ];

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

      Future<void> sendBin(int kind, Uint8List payload) async {
        if (_streamGeneration != gen) return;
        if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
        if (payload.isEmpty) return;
        const maxChunk = 60 * 1024;
        var off = 0;
        var chunksSent = 0;
        while (off < payload.length) {
          if (_streamGeneration != gen) return;
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
          final gate = _streamFlowGate;
          if (gate != null && !gate.isCompleted) {
            print('[ShareP2P] flow-control: paused (gen=$gen, sent=$totalBytesSent)');
            await gate.future;
            print('[ShareP2P] flow-control: resumed (gen=$gen)');
            if (_streamGeneration != gen) return;
          }
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) return;
          final end = math.min(off + maxChunk, payload.length);
          final slice = payload.sublist(off, end);
          _dc!.send(RTCDataChannelMessage.fromBinary(_wrapBin(kind, slice)));
          totalBytesSent += slice.length;
          off = end;
          chunksSent++;
          while ((_dc?.bufferedAmount ?? 0) > 512 * 1024) {
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
          if (_dc?.state != RTCDataChannelState.RTCDataChannelOpen) {
            try {
              proc.kill(ProcessSignal.sigkill);
            } catch (_) {}
            return;
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
      } else {
        final code = await proc.exitCode;
        _activeStreamProc = null;
        final stderr = stderrBuf.toString().trim();
        print('[ShareP2P] ffmpeg exited: code=$code');
        if (stderr.isNotEmpty) print('[ShareP2P] ffmpeg stderr: $stderr');
        if (code != 0 || !tempFile!.existsSync()) {
          print('[ShareP2P] ffmpeg failed or no output file');
          return;
        }
        print('[ShareP2P] temp fMP4 size: ${tempFile.lengthSync()} bytes');
        await processChunks(tempFile.openRead());
      }

      if (_streamGeneration == gen && initSent && pending.isNotEmpty) {
        await sendBin(kBinSeg, pending);
      }
      print('[ShareP2P] stream pipeline finished (gen=$gen, current=${_streamGeneration}, sent=$totalBytesSent)');
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

  void _killActiveStream() {
    try {
      _activeStreamProc?.kill(ProcessSignal.sigkill);
    } catch (_) {}
    _activeStreamProc = null;
  }

  Future<void> _onStreamSeek(Map<String, dynamic> msg) async {
    final targetTime = (msg['targetTime'] as num?)?.toDouble() ?? 0.0;
    final ffmpegPath = _activeStreamFfmpeg;
    final filePath = _activeStreamFile;
    if (ffmpegPath == null || filePath == null) return;

    // Invalidate old pipeline first so it stops sending.
    _streamGeneration++;
    _killActiveStream();

    if (_streamFlowGate != null && !_streamFlowGate!.isCompleted) {
      _streamFlowGate!.complete();
    }
    _streamFlowGate = null;

    // Yield so the old pipeline's async loops notice the generation change and exit.
    await Future.delayed(Duration.zero);

    _sendJson({'type': 'stream-seeked', 'actualTime': targetTime});

    await _runStreamPipeline(ffmpegPath, filePath, seekTime: targetTime);
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
    _killActiveStream();
    if (_downloadAckCompleter != null && !_downloadAckCompleter!.isCompleted) {
      _downloadAckCompleter!.complete();
    }
    _downloadAckCompleter = null;
    _dc?.close();
    await _pc?.close();
    _dc = null;
    _pc = null;
  }
}
