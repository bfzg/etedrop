import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/http/cancel_token.dart';
import '../../../core/utils/resumable_transfer.dart';
import '../models/lan_share_payload.dart';
import 'lan_http_client_upload.dart';

void _lanUploadLog(String message) {
  developer.log(message, name: 'LAN.upload');
}

void _lanUploadLogHttpResult(String url, HttpClientUploadResult r) {
  _lanUploadLog(
    '[LAN /upload][send] FAIL url=$url status=${r.statusCode} '
    'preview=${r.bodyPreview} err=${r.error} (${r.error.runtimeType})',
  );
  if (r.stackTrace != null) {
    _lanUploadLog('[LAN /upload][send] stack:\n${r.stackTrace}');
  }
}

HttpClient _newLanPeerClient() {
  final c = HttpClient();
  c.connectionTimeout = const Duration(minutes: 10);
  c.idleTimeout = const Duration(days: 365);
  return c;
}

class LanTransferService {
  LanTransferService();

  Future<bool> ping(String ip, int port) async {
    final client = _newLanPeerClient();
    try {
      final uri = Uri(scheme: 'http', host: ip, port: port, path: '/ping');
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 2));
      await res.drain<void>();
      return res.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> sendFile({
    required String ip,
    required int port,
    required String filePath,
    required String senderName,
    required int senderAvatar,
    required String senderDeviceId,
    Function(double)? onProgress,
    LanCancelToken? cancelToken,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found');
    }

    final fileName = p.basename(filePath);
    final fileSize = await file.length();

    await sendFileStream(
      ip: ip,
      port: port,
      fileStream: fileOpenReadChunked(file, 0, fileSize),
      fileName: fileName,
      fileSize: fileSize,
      senderName: senderName,
      senderAvatar: senderAvatar,
      senderDeviceId: senderDeviceId,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> _postJson(
    String url,
    Map<String, dynamic> body,
    Duration timeout,
  ) async {
    final client = _newLanPeerClient();
    try {
      final uri = Uri.parse(url);
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      final bytes = utf8.encode(jsonEncode(body));
      req.contentLength = bytes.length;
      req.add(bytes);
      final res = await req.close().timeout(timeout);
      await res.drain<void>();
      if (res.statusCode != HttpStatus.ok) {
        throw Exception('HTTP ${res.statusCode}');
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> postShareOffer({
    required String ip,
    required int port,
    required LanShareOfferPayload payload,
  }) async {
    final url = 'http://$ip:$port/share-offer';
    await _postJson(url, payload.toJson(), const Duration(seconds: 15));
  }

  Future<void> postShareAccept({
    required String senderHost,
    required int senderPort,
    required LanShareAcceptPayload payload,
  }) async {
    final url = 'http://$senderHost:$senderPort/share-accept';
    await _postJson(url, payload.toJson(), const Duration(seconds: 15));
  }

  Future<void> postShareCancel({
    required String ip,
    required int port,
    required LanShareCancelPayload payload,
  }) async {
    final url = 'http://$ip:$port/share-cancel';
    await _postJson(url, payload.toJson(), const Duration(seconds: 10));
  }

  /// 查询对端已写入字节数（与 [sendFileStream] 使用相同的 `fileName` / `shareId` / `fileIndex`）。
  Future<int> fetchRemoteWrittenBytes({
    required String ip,
    required int port,
    required String fileName,
    String? shareId,
    int fileIndex = 0,
  }) async {
    final uri = Uri(
      scheme: 'http',
      host: ip,
      port: port,
      path: '/upload-state',
      queryParameters: <String, String>{
        'file': fileName,
        'shareId': shareId ?? '',
        'fileIndex': '$fileIndex',
      },
    );
    final client = _newLanPeerClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close().timeout(const Duration(seconds: 10));
      final text = await utf8.decodeStream(res).timeout(const Duration(seconds: 10));
      if (res.statusCode != HttpStatus.ok) return 0;
      dynamic data = jsonDecode(text);
      if (data is String) {
        data = jsonDecode(data) as Map<String, dynamic>?;
      }
      if (data is! Map) return 0;
      final o = data['offset'];
      if (o is int) return o;
      if (o is num) return o.toInt();
      return 0;
    } catch (_) {
      return 0;
    } finally {
      client.close(force: true);
    }
  }

  /// 大文件走 [dart:io] [HttpClient]（显式关闭 idle 超时），避免 Dio 包装层长传断连。
  Future<void> _postUploadOctetStream({
    required String url,
    required Stream<List<int>> fileStream,
    required Map<String, dynamic> headers,
    LanCancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final uri = Uri.parse(url);
    final clRaw = headers[HttpHeaders.contentLengthHeader];
    final contentLength = clRaw is int ? clRaw : int.parse(clRaw.toString());
    final stringHeaders = headers.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );

    final result = await httpClientUploadOctetStream(
      uri: uri,
      contentLength: contentLength,
      headers: stringHeaders,
      body: fileStream,
      onProgress: onSendProgress == null
          ? null
          : (sent, total) => onSendProgress(sent, total),
      isCancelled: cancelTokenToChecker(cancelToken),
    );

    if (result.isSuccess) return;

    _lanUploadLogHttpResult(url, result);
    if (result.statusCode == HttpStatus.forbidden) {
      throw Exception('对方拒绝了接收文件');
    }
    if (result.statusCode == HttpStatus.conflict) {
      throw Exception('断点不一致，请重试: ${result.bodyPreview}');
    }
    final err = result.error;
    final tail = err != null ? '$err' : (result.bodyPreview ?? 'unknown');
    throw Exception('传输失败: $tail');
  }

  Future<void> sendFileStream({
    required String ip,
    required int port,
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderName,
    required int senderAvatar,
    required String senderDeviceId,
    String? shareId,
    int fileIndex = 0,
    int fileCount = 1,
    int batchTotalBytes = 0,

    /// 从源文件的该偏移开始发送（请求体长度为 fileSize - resumeFromOffset）。
    int resumeFromOffset = 0,
    Function(double)? onProgress,
    LanCancelToken? cancelToken,
  }) async {
    final url = 'http://$ip:$port/upload';
    final total = batchTotalBytes > 0 ? batchTotalBytes : fileSize;
    final remaining = resumableRemainingBytes(
      totalSize: fileSize,
      resumeOffset: resumeFromOffset,
    );

    try {
      final headers = <String, dynamic>{
        'X-File-Name': Uri.encodeComponent(fileName),
        'X-Sender-Name': Uri.encodeComponent(senderName),
        'X-Sender-Avatar': senderAvatar.toString(),
        'X-Sender-Device-Id': senderDeviceId,
        'X-File-Size': fileSize.toString(),
        'X-File-Index': fileIndex.toString(),
        'X-File-Count': fileCount.toString(),
        'X-Batch-Total-Bytes': total.toString(),
        ResumableTransferHeaders.resumeOffset: resumeFromOffset.toString(),
        HttpHeaders.contentLengthHeader: remaining,
        HttpHeaders.contentTypeHeader: 'application/octet-stream',
      };
      if (shareId != null) {
        headers['X-Share-Id'] = shareId;
      }
      _lanUploadLog(
        '[LAN /upload][send] POST $url file=$fileName '
        'resume=$resumeFromOffset remaining=$remaining fileSize=$fileSize',
      );
      await _postUploadOctetStream(
        url: url,
        fileStream: fileStream,
        headers: headers,
        cancelToken: cancelToken,
        onSendProgress: (count, totalBytes) {
          if (totalBytes > 0 && onProgress != null) {
            onProgress(count / totalBytes);
          }
        },
      );
      _lanUploadLog(
        '[LAN /upload][send] response OK $url file=$fileName',
      );
    } on LanUploadCancelledException {
      throw Exception('传输已取消');
    }
  }

  /// 大文件：失败自动按对端已写字节续传；取消请使用 [cancelToken]。
  ///
  /// [onProgress] 为整体进度 0~1：单文件时为已传字节/文件大小；批量时为本批已传字节/
  /// [batchTotalBytes]（需传入前面各文件体积之和 [batchBaseBytes]）。
  Future<void> sendLocalFileWithResume({
    required String ip,
    required int port,
    required String filePath,
    required String senderName,
    required int senderAvatar,
    required String senderDeviceId,
    String? shareId,
    int fileIndex = 0,
    int fileCount = 1,
    int batchTotalBytes = 0,
    /// 本文件之前各文件体积之和（批量时用于 [onProgress]）。
    int batchBaseBytes = 0,
    void Function(double overallProgress01)? onProgress,
    LanCancelToken? cancelToken,
    int maxAttempts = 48,
  }) async {
    final f = File(filePath);
    if (!await f.exists()) {
      throw Exception('File not found');
    }
    final fileName = p.basename(filePath);
    final fileSize = await f.length();

    void reportOverallBytesInFile(int uploadedInFile) {
      if (onProgress == null) return;
      final denom = batchTotalBytes > 0 ? batchTotalBytes : fileSize;
      if (denom <= 0) return;
      final numer = batchTotalBytes > 0
          ? batchBaseBytes + uploadedInFile
          : uploadedInFile;
      onProgress((numer / denom).clamp(0.0, 1.0));
    }

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (cancelToken?.isCancelled == true) {
        throw Exception('传输已取消');
      }

      var start = 0;
      try {
        start = await fetchRemoteWrittenBytes(
          ip: ip,
          port: port,
          fileName: fileName,
          shareId: shareId,
          fileIndex: fileIndex,
        );
      } catch (_) {
        start = 0;
      }

      if (start < 0) start = 0;
      if (start > fileSize) start = fileSize;
      if (start == fileSize) {
        reportOverallBytesInFile(fileSize);
        return;
      }

      final url = 'http://$ip:$port/upload';
      final total = batchTotalBytes > 0 ? batchTotalBytes : fileSize;
      final remaining = resumableRemainingBytes(
        totalSize: fileSize,
        resumeOffset: start,
      );
      final headers = <String, dynamic>{
        'X-File-Name': Uri.encodeComponent(fileName),
        'X-Sender-Name': Uri.encodeComponent(senderName),
        'X-Sender-Avatar': senderAvatar.toString(),
        'X-Sender-Device-Id': senderDeviceId,
        'X-File-Size': fileSize.toString(),
        'X-File-Index': fileIndex.toString(),
        'X-File-Count': fileCount.toString(),
        'X-Batch-Total-Bytes': total.toString(),
        ResumableTransferHeaders.resumeOffset: start.toString(),
        HttpHeaders.contentLengthHeader: remaining,
        HttpHeaders.contentTypeHeader: 'application/octet-stream',
      };
      if (shareId != null) {
        headers['X-Share-Id'] = shareId;
      }

      try {
        _lanUploadLog(
          '[LAN /upload][send] POST attempt=${attempt + 1}/$maxAttempts $url '
          'file=$fileName start=$start remaining=$remaining fileSize=$fileSize',
        );
        await _postUploadOctetStream(
          url: url,
          fileStream: fileOpenReadChunked(f, start, fileSize),
          headers: headers,
          cancelToken: cancelToken,
          onSendProgress: (count, totalBytes) {
            if (totalBytes > 0 && onProgress != null) {
              reportOverallBytesInFile(start + count);
            }
          },
        );
        _lanUploadLog(
          '[LAN /upload][send] response OK $url file=$fileName',
        );
        reportOverallBytesInFile(fileSize);
        return;
      } on LanUploadCancelledException {
        throw Exception('传输已取消');
      } on Exception catch (e) {
        final msg = e.toString();
        final isForbidden = msg.contains('对方拒绝了接收文件');
        final isConflict = msg.contains('断点不一致') ||
            msg.contains('No active receive session');
        if (isForbidden) rethrow;
        if (attempt >= maxAttempts - 1) {
          rethrow;
        }
        if (isConflict) {
          _lanUploadLog(
            '[LAN /upload][send] resume conflict, will restart from 0 '
            'file=$fileName (attempt ${attempt + 1})',
          );
        } else {
          _lanUploadLog(
            '[LAN /upload][send] will retry after '
            '${200 + attempt * 100}ms (attempt ${attempt + 1}) err=$e',
          );
        }
        await Future<void>.delayed(Duration(milliseconds: 200 + attempt * 100));
      }
    }
  }
}

/// 与 Dio [ProgressCallback] 签名一致，便于与 [httpClientUploadOctetStream] 对接。
typedef ProgressCallback = void Function(int count, int total);
