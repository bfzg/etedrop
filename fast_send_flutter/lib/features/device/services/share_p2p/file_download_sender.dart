import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'p2p_constants.dart';
import 'p2p_download_log.dart';

/// 与 share-page-app 一致：`[0..8)` 大端 uint64 偏移 + payload。
Uint8List encodeShareP2pOffsetPrefixedChunk(int fileOffset, Uint8List payload) {
  final out = Uint8List(8 + payload.length);
  ByteData.sublistView(out, 0, 8).setUint64(0, fileOffset, Endian.big);
  out.setRange(8, 8 + payload.length, payload);
  return out;
}

class ShareP2pDownloadSendBindings {
  ShareP2pDownloadSendBindings({
    required this.dc,
    required this.awaitDownloadAck,
    required this.downloadFlowGate,
  });

  final RTCDataChannel? Function() dc;
  final Future<void> Function() awaitDownloadAck;
  final Completer<void>? Function() downloadFlowGate;
}

Future<void> sendShareP2pSmallFileFastPath(
  ShareP2pDownloadSendBindings b,
  Uint8List bytes,
) async {
  if (bytes.isEmpty) return;
  final channel = b.dc();
  if (bytes.length <= shareP2pSmallFileSingleSendMaxBytes) {
    if (channel?.state != RTCDataChannelState.RTCDataChannelOpen) return;
    channel!.send(RTCDataChannelMessage.fromBinary(bytes));
    return;
  }

  var offset = 0;
  final cap = shareP2pSmallFileLegacyChunkBytes;
  final len = bytes.length;
  while (offset < len) {
    final c = b.dc();
    if (c?.state != RTCDataChannelState.RTCDataChannelOpen) return;
    final end = math.min(offset + cap, len);
    c!.send(RTCDataChannelMessage.fromBinary(bytes.sublist(offset, end)));
    offset = end;
    while ((b.dc()?.bufferedAmount ?? 0) > shareP2pDownloadMaxBufferedBytes) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }
}

Future<void> runShareP2pChunkedDownloadFromRaf({
  required ShareP2pDownloadSendBindings b,
  required RandomAccessFile raf,
  required int fileSize,
  required int startPos,
  required int chunkCap,
}) async {
  var pos = startPos;
  var lastLogPos = pos;
  const logEveryBytes = 5 * 1024 * 1024;
  var sentSinceAck = 0;

  while (pos < fileSize) {
    if (b.dc()?.state != RTCDataChannelState.RTCDataChannelOpen) {
      shareP2pDownloadLog(
        'abort send loop: dc not open at pos=$pos/$fileSize state=${b.dc()?.state}',
      );
      return;
    }
    final gate = b.downloadFlowGate();
    if (gate != null && !gate.isCompleted) {
      shareP2pDownloadLog(
        'await downloadFlowGate pos=$pos/$fileSize buffered=${b.dc()?.bufferedAmount ?? -1}',
      );
      await gate.future;
      shareP2pDownloadLog(
        'gate released pos=$pos/$fileSize buffered=${b.dc()?.bufferedAmount ?? -1}',
      );
    }
    if (b.dc()?.state != RTCDataChannelState.RTCDataChannelOpen) {
      shareP2pDownloadLog(
        'abort send loop after gate: dc not open at pos=$pos/$fileSize',
      );
      return;
    }

    final toRead = math.min(chunkCap, fileSize - pos);
    final payload = await raf.read(toRead);
    if (payload.isEmpty) break;

    final ch = b.dc();
    if (ch?.state != RTCDataChannelState.RTCDataChannelOpen) return;
    final packet = encodeShareP2pOffsetPrefixedChunk(pos, payload);
    ch!.send(RTCDataChannelMessage.fromBinary(packet));
    pos += payload.length;
    sentSinceAck += payload.length;

    var spin = 0;
    while ((b.dc()?.bufferedAmount ?? 0) > shareP2pDownloadMaxBufferedBytes) {
      if (spin == 200) {
        shareP2pDownloadLog(
          'bufferedAmount spin ~1s pos=$pos/$fileSize buf=${b.dc()?.bufferedAmount}',
        );
      }
      spin++;
      await Future.delayed(const Duration(milliseconds: 5));
    }

    if (sentSinceAck >= shareP2pDownloadAckWindowBytes) {
      try {
        await b.awaitDownloadAck();
      } catch (e) {
        shareP2pDownloadLog('download-ack failed: $e');
        if (b.dc()?.state != RTCDataChannelState.RTCDataChannelOpen) {
          return;
        }
        rethrow;
      }
      sentSinceAck = 0;
    }

    if (pos - lastLogPos >= logEveryBytes || pos >= fileSize) {
      shareP2pDownloadLog(
        'progress pos=$pos/$fileSize buffered=${b.dc()?.bufferedAmount ?? -1}',
      );
      lastLogPos = pos;
    }
  }
  if (sentSinceAck > 0) {
    try {
      await b.awaitDownloadAck();
    } catch (e) {
      shareP2pDownloadLog('final download-ack failed: $e');
      if (b.dc()?.state != RTCDataChannelState.RTCDataChannelOpen) {
        return;
      }
      rethrow;
    }
  }
}
