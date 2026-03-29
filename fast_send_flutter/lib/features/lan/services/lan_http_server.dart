import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/resumable_transfer.dart';
import '../models/lan_share_payload.dart';
import 'lan_http_context.dart';

class LanHttpServer {
  HttpServer? _server;
  final String saveDirectory;
  final String deviceId;

  /// 收到分享邀约（仅元数据，不含文件）
  final Future<void> Function(LanShareOfferPayload offer)? onShareOffer;

  /// 接收方回调发送方：用户已接受/拒绝（仅发送端需要处理）
  final Future<void> Function(LanShareAcceptPayload payload)? onShareAccept;

  /// 发送方取消分享
  final Future<void> Function(LanShareCancelPayload cancel)? onShareCancel;

  /// 是否允许开始写入本次上传（批量时除首个文件外通常直接 true）
  final Future<bool> Function(LanUploadContext ctx)? onReceiveUpload;

  /// 上传进度：当前文件内进度 + 整批总进度（0~1）
  final void Function(
    LanUploadContext ctx,
    double fileProgress,
    double batchProgress,
  )?
  onProgress;

  final void Function(LanUploadContext ctx)? onComplete;
  final void Function(LanUploadContext ctx, String error)? onError;

  LanHttpServer({
    required this.saveDirectory,
    required this.deviceId,
    this.onShareOffer,
    this.onShareAccept,
    this.onShareCancel,
    this.onReceiveUpload,
    this.onProgress,
    this.onComplete,
    this.onError,
  });

  Future<int> start({int port = 0}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    // 大文件上传若长时间无「空闲」以外的读超时，默认空闲超时会误杀连接。
    _server!.idleTimeout = null;
    debugPrint('LAN HTTP Server listening on port ${_server!.port}');

    _server!.listen(_handleRequest);
    return _server!.port;
  }

  void stop() {
    _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      if (request.method == 'GET' && request.uri.path == '/ping') {
        _handlePing(request);
      } else if (request.method == 'GET' &&
          request.uri.path == '/upload-state') {
        await _handleUploadState(request);
      } else if (request.method == 'POST' &&
          request.uri.path == '/share-offer') {
        await _handleShareOffer(request);
      } else if (request.method == 'POST' &&
          request.uri.path == '/share-accept') {
        await _handleShareAccept(request);
      } else if (request.method == 'POST' &&
          request.uri.path == '/share-cancel') {
        await _handleShareCancel(request);
      } else if (request.method == 'POST' && request.uri.path == '/upload') {
        await _handleUpload(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    } catch (e) {
      debugPrint('HTTP Server Error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  void _handlePing(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'status': 'ok', 'deviceId': deviceId}));
    request.response.close();
  }

  Future<void> _handleShareOffer(HttpRequest request) async {
    if (onShareOffer == null) {
      request.response.statusCode = HttpStatus.notImplemented;
      await request.response.close();
      return;
    }
    try {
      final raw = await utf8.decoder.bind(request).join();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final payload = LanShareOfferPayload.fromJson(map);
      await onShareOffer!(payload);
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true}));
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(e.toString());
    }
    await request.response.close();
  }

  Future<void> _handleShareAccept(HttpRequest request) async {
    if (onShareAccept == null) {
      request.response.statusCode = HttpStatus.notImplemented;
      await request.response.close();
      return;
    }
    try {
      final raw = await utf8.decoder.bind(request).join();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final payload = LanShareAcceptPayload.fromJson(map);
      await onShareAccept!(payload);
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true}));
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(e.toString());
    }
    await request.response.close();
  }

  Future<void> _handleShareCancel(HttpRequest request) async {
    if (onShareCancel == null) {
      request.response.statusCode = HttpStatus.notImplemented;
      await request.response.close();
      return;
    }
    try {
      final raw = await utf8.decoder.bind(request).join();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final payload = LanShareCancelPayload.fromJson(map);
      await onShareCancel!(payload);
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true}));
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(e.toString());
    }
    await request.response.close();
  }

  Future<void> _handleUploadState(HttpRequest request) async {
    try {
      final rawName = request.uri.queryParameters['file'];
      if (rawName == null || rawName.isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('missing file');
        await request.response.close();
        return;
      }
      final name = Uri.decodeComponent(rawName);
      final safeName = p.basename(name);
      if (safeName.isEmpty || safeName != name) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }
      final path = p.join(saveDirectory, safeName);
      final f = File(path);
      final offset = await f.exists() ? await f.length() : 0;
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"offset":$offset}');
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(e.toString());
    }
    await request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request) async {
    final fileNameEncoded = request.headers.value('X-File-Name');
    final senderNameEncoded = request.headers.value('X-Sender-Name');
    final senderAvatarStr = request.headers.value('X-Sender-Avatar');
    final senderDeviceId = request.headers.value('X-Sender-Device-Id') ?? '';
    final fileSizeStr = request.headers.value('X-File-Size');
    final shareId = request.headers.value('X-Share-Id');
    final fileIndexStr = request.headers.value('X-File-Index');
    final fileCountStr = request.headers.value('X-File-Count');
    final batchTotalStr = request.headers.value('X-Batch-Total-Bytes');
    final resumeOffsetStr = request.headers.value(
      ResumableTransferHeaders.resumeOffset,
    );
    final resumeOffset = int.tryParse(resumeOffsetStr ?? '0') ?? 0;

    if (fileNameEncoded == null || senderNameEncoded == null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing headers');
      await request.response.close();
      return;
    }

    final fileName = Uri.decodeComponent(fileNameEncoded);
    final senderName = Uri.decodeComponent(senderNameEncoded);
    final fileSize = int.tryParse(fileSizeStr ?? '0') ?? 0;
    final senderAvatar = int.tryParse(senderAvatarStr ?? '1') ?? 1;
    final fileIndex = int.tryParse(fileIndexStr ?? '0') ?? 0;
    final fileCount = int.tryParse(fileCountStr ?? '1') ?? 1;
    final batchTotalBytes =
        int.tryParse(batchTotalStr ?? '$fileSize') ?? fileSize;

    final ctx = LanUploadContext(
      fileName: fileName,
      fileSize: fileSize,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderDeviceId: senderDeviceId,
      shareId: shareId,
      fileIndex: fileIndex,
      fileCount: fileCount,
      batchTotalBytes: batchTotalBytes,
    );

    final peer = request.connectionInfo?.remoteAddress.address ?? '?';
    final expectBody = fileSize > resumeOffset ? fileSize - resumeOffset : 0;
    debugPrint(
      '[LAN /upload][recv] start peer=$peer file=$fileName '
      'size=$fileSize resume=$resumeOffset expectBody=$expectBody '
      'idx=$fileIndex/$fileCount',
    );

    if (onReceiveUpload != null) {
      final accepted = await onReceiveUpload!(ctx);
      if (accepted != true) {
        debugPrint('[LAN /upload][recv] rejected by user peer=$peer file=$fileName');
        request.response.statusCode = HttpStatus.forbidden;
        request.response.write('Rejected by user');
        await request.response.close();
        return;
      }
    }

    final savePath = p.join(saveDirectory, fileName);
    final file = File(savePath);

    late final IOSink sink;
    try {
      sink = await openReceiverSinkForResume(
        targetFile: file,
        declaredOffset: resumeOffset,
        declaredTotalSize: fileSize,
      );
    } on ResumableTransferException catch (e) {
      debugPrint(
        '[LAN /upload][recv] conflict peer=$peer file=$fileName: ${e.message}',
      );
      request.response.statusCode = HttpStatus.conflict;
      request.response.write(e.message);
      await request.response.close();
      return;
    }

    var receivedBytes = 0;
    // 更大 flush 间隔减少磁盘 fsync 频率，提升大文件吞吐（与频繁 UI 回调解耦）
    const flushStrideBytes = 16 * 1024 * 1024;
    var sinceFlush = 0;
    var sinceProgressBytes = 0;
    DateTime lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
    const progressMinInterval = Duration(milliseconds: 200);
    const progressMinBytes = 512 * 1024;

    var responseClosed = false;
    try {
      await for (final chunk in request) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        sinceFlush += chunk.length;
        if (sinceFlush >= flushStrideBytes) {
          sinceFlush = 0;
          await sink.flush();
        }
        if (onProgress != null) {
          sinceProgressBytes += chunk.length;
          final now = DateTime.now();
          final due = sinceProgressBytes >= progressMinBytes ||
              now.difference(lastProgressAt) >= progressMinInterval;
          if (due) {
            sinceProgressBytes = 0;
            lastProgressAt = now;
            final absolute = resumeOffset + receivedBytes;
            final inFile = fileSize > 0
                ? (absolute / fileSize).clamp(0.0, 1.0)
                : 0.0;
            final batchProgress = fileCount > 0
                ? ((fileIndex + inFile) / fileCount).clamp(0.0, 1.0)
                : inFile;
            onProgress!(ctx, inFile, batchProgress);
          }
        }
      }
      if (onProgress != null && fileSize > 0) {
        final inFile = 1.0;
        final batchProgress = fileCount > 0
            ? ((fileIndex + inFile) / fileCount).clamp(0.0, 1.0)
            : inFile;
        onProgress!(ctx, inFile, batchProgress);
      }
      await sink.flush();
      await sink.close();

      if (fileSize > 0) {
        final finalLen = await file.length();
        if (finalLen != fileSize) {
          throw StateError('长度不符: 期望 $fileSize，实际 $finalLen');
        }
      }

      request.response.headers.set(HttpHeaders.connectionHeader, 'close');
      request.response.statusCode = HttpStatus.ok;
      request.response.write('Success');
      await request.response.close();
      responseClosed = true;
      debugPrint(
        '[LAN /upload][recv] ok peer=$peer file=$fileName '
        'got=$receivedBytes bytes (resume+$receivedBytes vs size $fileSize)',
      );
    } catch (e, st) {
      debugPrint(
        '[LAN /upload][recv] FAIL peer=$peer file=$fileName '
        'receivedBytes=$receivedBytes expectBody=$expectBody '
        'responseClosed=$responseClosed err=$e',
      );
      debugPrint('[LAN /upload][recv] stack:\n$st');
      try {
        await sink.close();
      } catch (_) {}
      onError?.call(ctx, e.toString());
      if (!responseClosed) {
        try {
          request.response.headers.set(HttpHeaders.connectionHeader, 'close');
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (closeErr) {
          debugPrint('[LAN /upload][recv] error closing 500 response: $closeErr');
        }
      }
      return;
    }

    try {
      onComplete?.call(
        LanUploadContext(
          fileName: ctx.fileName,
          fileSize: ctx.fileSize,
          senderName: ctx.senderName,
          senderAvatar: ctx.senderAvatar,
          senderDeviceId: ctx.senderDeviceId,
          shareId: ctx.shareId,
          fileIndex: ctx.fileIndex,
          fileCount: ctx.fileCount,
          batchTotalBytes: ctx.batchTotalBytes,
          savedAbsolutePath: file.absolute.path,
        ),
      );
    } catch (e, st) {
      // 文件已落盘且 HTTP 200 已发出；此处失败不应再写 response，也不应把整次接收标为失败。
      debugPrint('LAN upload onComplete error: $e\n$st');
    }
  }
}
