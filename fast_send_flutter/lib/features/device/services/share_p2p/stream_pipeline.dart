import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path/path.dart' as p;

import '../video_stream_plan.dart';
import 'mp4_box_split.dart';
import 'p2p_constants.dart';

/// [ShareP2PHandler] 注入的运行时依赖，避免管道模块直接依赖 Handler 类型。
class ShareP2pStreamPipelineBindings {
  ShareP2pStreamPipelineBindings({
    required this.generation,
    required this.generationStillCurrent,
    required this.disposeRequested,
    required this.peerConnection,
    required this.dataChannel,
    required this.streamFlowGate,
    required this.releaseIdenticalStreamFlowGate,
    required this.sendJson,
    required this.setActiveStreamProcess,
    required this.awaitStreamDataAck,
    required this.queryPipeSupported,
  });

  final int generation;
  final bool Function() generationStillCurrent;
  final bool Function() disposeRequested;
  final RTCPeerConnection? Function() peerConnection;
  final RTCDataChannel? Function() dataChannel;
  final Completer<void>? Function() streamFlowGate;
  final void Function(Completer<void> gate) releaseIdenticalStreamFlowGate;
  final void Function(Map<String, dynamic> json) sendJson;
  final void Function(Process? proc) setActiveStreamProcess;
  final Future<void> Function(int minWireSeq) awaitStreamDataAck;
  final Future<bool> Function() queryPipeSupported;
}

/// ffmpeg → fMP4 分片 → DataChannel（init-segment-v2）。
Future<void> runShareP2pStreamPipeline(
  ShareP2pStreamPipelineBindings b,
  String ffmpegPath,
  String filePath, {
  required VideoStreamPlan plan,
  double? seekTime,
}) async {
  final gen = b.generation;
  final usePipe = await b.queryPipeSupported();
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

  var totalBytesSent = 0;
  try {
    // ignore: avoid_print
    print(
      '[ShareP2P] ffmpeg start (pipe=$usePipe, realtimePacing=${plan.useRealtimeInputPacing}): '
      '$ffmpegPath ${args.join(' ')}',
    );
    final proc = await Process.start(ffmpegPath, args);
    b.setActiveStreamProcess(proc);

    final stderrBuf = StringBuffer();
    proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((s) {
      stderrBuf.write(s);
    });

    var buf = Uint8List(0);
    var init = Uint8List(0);
    var sawMoov = false;
    var initSent = false;
    var pending = Uint8List(0);
    var sentSinceStreamAck = 0;
    var nextWireSeq = 0;

    bool isPcUnhealthyHard() {
      final pc = b.peerConnection();
      final s = pc?.connectionState;
      return pc == null ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateFailed;
    }

    bool isPcDisconnected() {
      final s = b.peerConnection()?.connectionState;
      return s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected;
    }

    Future<bool> waitForPcRecovery({int maxWaitMs = 5000}) async {
      if (!isPcDisconnected()) return !isPcUnhealthyHard();
      // ignore: avoid_print
      print(
        '[ShareP2P] pc=Disconnected during stream — pausing send up to '
        '${maxWaitMs}ms (gen=$gen, sent=$totalBytesSent)',
      );
      final start = DateTime.now();
      while (isPcDisconnected()) {
        if (!b.generationStillCurrent()) return false;
        if (b.disposeRequested()) return false;
        if (DateTime.now().difference(start).inMilliseconds > maxWaitMs) {
          // ignore: avoid_print
          print(
            '[ShareP2P] pc still Disconnected after ${maxWaitMs}ms — abort '
            'pipeline (gen=$gen, sent=$totalBytesSent)',
          );
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if (isPcUnhealthyHard()) return false;
      // ignore: avoid_print
      print(
        '[ShareP2P] pc recovered to ${b.peerConnection()?.connectionState} '
        '(gen=$gen, sent=$totalBytesSent)',
      );
      return true;
    }

    Future<void> sendBin(int kind, Uint8List payload) async {
      if (!b.generationStillCurrent()) return;
      if (b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen) {
        return;
      }
      if (payload.isEmpty) return;
      const seekFlowControlGraceMs = 1200;
      const pauseWatchdogMs = 4000;
      const pauseWatchdogBufferedBytes = 256 * 1024;
      const warmupChunkCount = 12;
      const warmupChunkBytes = 24 * 1024;

      int pickChunkSizeByBackpressure(int bufferedAmount) {
        if (bufferedAmount > 16 * 1024 * 1024) return 16 * 1024;
        if (bufferedAmount > 8 * 1024 * 1024) return 24 * 1024;
        if (bufferedAmount > 4 * 1024 * 1024) return 40 * 1024;
        return (64 * 1024) - shareP2pStreamBinHeaderV2Bytes;
      }

      var lastWireSeqThisChunk = 0;
      Uint8List wrapV2(int kind, Uint8List slice) {
        final s = nextWireSeq + 1;
        nextWireSeq = s;
        lastWireSeqThisChunk = s;
        final out = Uint8List(shareP2pStreamBinHeaderV2Bytes + slice.length);
        out[0] = shareP2pStreamBinVersionV2;
        out[1] = kind;
        final bd = ByteData.sublistView(out, 2, 6);
        bd.setUint32(0, s, Endian.big);
        out.setRange(shareP2pStreamBinHeaderV2Bytes, out.length, slice);
        return out;
      }

      final seekGraceUntil = seekTime != null
          ? DateTime.now().add(
              const Duration(milliseconds: seekFlowControlGraceMs),
            )
          : null;
      var off = 0;
      var chunksSent = 0;
      final targetBufferedBytes = plan.probe.isHighRes4k
          ? 3 * 1024 * 1024
          : 2 * 1024 * 1024;
      while (off < payload.length) {
        if (!b.generationStillCurrent()) return;
        if (b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen) {
          return;
        }
        if (isPcUnhealthyHard()) return;
        if (isPcDisconnected()) {
          final ok = await waitForPcRecovery();
          if (!ok) return;
          if (!b.generationStillCurrent()) return;
          if (b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen) {
            return;
          }
        }
        final gate = b.streamFlowGate();
        if (gate != null && !gate.isCompleted) {
          final inSeekGrace =
              seekGraceUntil != null &&
              DateTime.now().isBefore(seekGraceUntil);
          if (!inSeekGrace) {
            // ignore: avoid_print
            print(
              '[ShareP2P] flow-control: paused (gen=$gen, sent=$totalBytesSent)',
            );
            final pauseStart = DateTime.now();
            while (!gate.isCompleted) {
              await Future.any<void>([
                gate.future,
                Future<void>.delayed(const Duration(seconds: 1)),
              ]);
              if (!b.generationStillCurrent()) return;
              if (b.dataChannel()?.state !=
                  RTCDataChannelState.RTCDataChannelOpen) {
                return;
              }
              if (isPcUnhealthyHard()) return;
              if (gate.isCompleted) break;
              if (isPcDisconnected()) {
                final ok = await waitForPcRecovery();
                if (!ok) return;
              }
              final pausedMs =
                  DateTime.now().difference(pauseStart).inMilliseconds;
              final buffered = b.dataChannel()?.bufferedAmount ?? 0;
              if (pausedMs >= pauseWatchdogMs &&
                  buffered <= pauseWatchdogBufferedBytes) {
                // ignore: avoid_print
                print(
                  '[ShareP2P] flow-control watchdog release '
                  '(pausedMs=$pausedMs, buffered=$buffered, gen=$gen)',
                );
                b.releaseIdenticalStreamFlowGate(gate);
                break;
              }
            }
            // ignore: avoid_print
            print('[ShareP2P] flow-control: resumed (gen=$gen)');
          }
        }
        if (b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen) {
          return;
        }
        while ((b.dataChannel()?.bufferedAmount ?? 0) > targetBufferedBytes) {
          if (!b.generationStillCurrent()) return;
          if (b.dataChannel()?.state !=
              RTCDataChannelState.RTCDataChannelOpen) {
            return;
          }
          if (isPcUnhealthyHard()) return;
          await Future.delayed(const Duration(milliseconds: 2));
        }
        final buffered = b.dataChannel()?.bufferedAmount ?? 0;
        var maxChunk = pickChunkSizeByBackpressure(buffered);
        if (chunksSent < warmupChunkCount && kind != kBinInit) {
          maxChunk = math.min(maxChunk, warmupChunkBytes);
        }
        final end = math.min(off + maxChunk, payload.length);
        final slice = payload.sublist(off, end);
        b.dataChannel()!.send(
          RTCDataChannelMessage.fromBinary(wrapV2(kind, slice)),
        );
        totalBytesSent += slice.length;
        off = end;
        chunksSent++;
        if (kind == kBinSeg) {
          sentSinceStreamAck += slice.length;
          if (sentSinceStreamAck >= shareP2pStreamDataAckWindowBytes) {
            try {
              await b.awaitStreamDataAck(lastWireSeqThisChunk);
            } catch (_) {
              if (b.dataChannel()?.state !=
                  RTCDataChannelState.RTCDataChannelOpen) {
                return;
              }
              rethrow;
            }
            sentSinceStreamAck = 0;
          }
        }
        final highWatermark = plan.probe.isHighRes4k
            ? 4 * 1024 * 1024
            : 3 * 1024 * 1024;
        while ((b.dataChannel()?.bufferedAmount ?? 0) > highWatermark) {
          await Future.delayed(const Duration(milliseconds: 2));
        }
        if (chunksSent % 8 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    }

    Future<void> processChunks(Stream<List<int>> source) async {
      await for (final chunk in source) {
        if (!b.generationStillCurrent()) return;
        if (b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen ||
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

        final split = splitIsoBmffBoxes(buf);
        buf = split.rest;

        for (final box in split.boxes) {
          if (!initSent) {
            if (isoBmffBoxTypeEquals(box, 'moov')) sawMoov = true;
            if (isoBmffBoxTypeEquals(box, 'moof')) {
              if (!sawMoov) {
                b.sendJson({
                  'type': 'error',
                  'code': 'STREAM_INIT_INVALID',
                  'message': '视频在线播放初始化失败（缺少 moov）',
                });
                return;
              }
              // ignore: avoid_print
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

          if (isoBmffBoxTypeEquals(box, 'moof')) {
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
      b.setActiveStreamProcess(null);
      final stderr = stderrBuf.toString().trim();
      final brokenPipe =
          stderr.contains('Broken pipe') ||
          stderr.contains('error code: -32');
      final interrupted =
          !b.generationStillCurrent() ||
          b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen;
      // ignore: avoid_print
      print('[ShareP2P] ffmpeg exited: code=$code');
      if (stderr.isNotEmpty) {
        // ignore: avoid_print
        print('[ShareP2P] ffmpeg stderr: $stderr');
      }
      if (code != 0) {
        if (interrupted || brokenPipe) {
          // ignore: avoid_print
          print(
            '[ShareP2P] ignore ffmpeg non-zero exit (interrupted=$interrupted, brokenPipe=$brokenPipe, gen=$gen)',
          );
          return;
        }
        b.sendJson({
          'type': 'error',
          'code': 'STREAM_TRANSCODE_FAILED',
          'message': '视频转码失败，当前设备内置 ffmpeg 可能缺少对应格式或编码支持',
        });
        return;
      }
      if (!initSent && pending.isEmpty && totalBytesSent == 0) {
        b.sendJson({
          'type': 'error',
          'code': 'STREAM_EMPTY_OUTPUT',
          'message': '视频转码未产出可播放数据，请尝试下载后使用本地播放器打开',
        });
        return;
      }
    } else {
      final code = await proc.exitCode;
      b.setActiveStreamProcess(null);
      final stderr = stderrBuf.toString().trim();
      final brokenPipe =
          stderr.contains('Broken pipe') ||
          stderr.contains('error code: -32');
      final interrupted =
          !b.generationStillCurrent() ||
          b.dataChannel()?.state != RTCDataChannelState.RTCDataChannelOpen;
      // ignore: avoid_print
      print('[ShareP2P] ffmpeg exited: code=$code');
      if (stderr.isNotEmpty) {
        // ignore: avoid_print
        print('[ShareP2P] ffmpeg stderr: $stderr');
      }
      if (code != 0 || !tempFile!.existsSync()) {
        if (code != 0 && (interrupted || brokenPipe)) {
          // ignore: avoid_print
          print(
            '[ShareP2P] ignore ffmpeg non-zero exit (interrupted=$interrupted, brokenPipe=$brokenPipe, gen=$gen)',
          );
          return;
        }
        // ignore: avoid_print
        print('[ShareP2P] ffmpeg failed or no output file');
        return;
      }
      // ignore: avoid_print
      print('[ShareP2P] temp fMP4 size: ${tempFile.lengthSync()} bytes');
      await processChunks(tempFile.openRead());
    }

    if (b.generationStillCurrent() && initSent && pending.isNotEmpty) {
      await sendBin(kBinSeg, pending);
    }
    // ignore: avoid_print
    print(
      '[ShareP2P] stream pipeline finished (gen=$gen, sent=$totalBytesSent)',
    );
  } finally {
    b.setActiveStreamProcess(null);
    if (tempFile != null) {
      try {
        if (tempFile.existsSync()) await tempFile.delete();
      } catch (_) {}
    }
  }

  if (!b.generationStillCurrent()) {
    // ignore: avoid_print
    print('[ShareP2P] stream gen=$gen cancelled, skipping stream-done');
    return;
  }
  if (b.dataChannel()?.state == RTCDataChannelState.RTCDataChannelOpen) {
    // ignore: avoid_print
    print('[ShareP2P] sending stream-done (gen=$gen)');
    b.sendJson({'type': 'stream-done'});
  } else {
    // ignore: avoid_print
    print(
      '[ShareP2P] skip stream-done (gen=$gen): dc state=${b.dataChannel()?.state} (对端可能已断开)',
    );
  }
}
