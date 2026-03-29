import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// 使用 [dart:io] [HttpClient] 流式 POST 大文件（与 LocalSend/reqwest 一样走系统 HTTP 栈），
/// 避免 Dio 包装层在长传、背压场景下与默认 idle 策略叠加导致对端看到「Connection closed」。
Future<HttpClientUploadResult> httpClientUploadOctetStream({
  required Uri uri,
  required int contentLength,
  required Map<String, String> headers,
  required Stream<List<int>> body,
  void Function(int sent, int total)? onProgress,
  bool Function()? isCancelled,
}) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(minutes: 30);
  // 长传时若对端短暂背压，默认 15s idle 可能关连接，表现为接收端 HttpException: Connection closed
  // （部分 SDK 上 idleTimeout 不可为 null，用超长时长等效关闭）
  client.idleTimeout = const Duration(days: 365);
  HttpClientRequest? request;
  try {
    request = await client.postUrl(uri);
    request.persistentConnection = true;
    request.contentLength = contentLength;
    headers.forEach((String k, String v) {
      final lower = k.toLowerCase();
      if (lower == 'content-length') return;
      request!.headers.set(k, v);
    });

    final counting = _countBytesStream(
      body,
      total: contentLength,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
    await request.addStream(counting);
    final response = await request.close();
    final status = response.statusCode;
    final preview = await _readSmallResponsePreview(response);
    return HttpClientUploadResult(
      statusCode: status,
      bodyPreview: preview,
    );
  } on SocketException catch (e, st) {
    return HttpClientUploadResult(
      statusCode: null,
      error: e,
      stackTrace: st,
    );
  } on HttpException catch (e, st) {
    return HttpClientUploadResult(
      statusCode: null,
      error: e,
      stackTrace: st,
    );
  } on IOException catch (e, st) {
    return HttpClientUploadResult(
      statusCode: null,
      error: e,
      stackTrace: st,
    );
  } finally {
    client.close(force: true);
  }
}

class HttpClientUploadResult {
  HttpClientUploadResult({
    this.statusCode,
    this.bodyPreview,
    this.error,
    this.stackTrace,
  });

  final int? statusCode;
  final String? bodyPreview;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isSuccess => statusCode == HttpStatus.ok;
}

Future<String> _readSmallResponsePreview(HttpClientResponse response) async {
  final buf = StringBuffer();
  var previewLen = 0;
  const maxPreview = 4096;
  await for (final chunk in response) {
    if (chunk.isEmpty) continue;
    if (previewLen < maxPreview) {
      final take = chunk.length < maxPreview - previewLen
          ? chunk.length
          : maxPreview - previewLen;
      buf.write(String.fromCharCodes(chunk.sublist(0, take)));
      previewLen += take;
    }
  }
  return buf.toString();
}

Stream<List<int>> _countBytesStream(
  Stream<List<int>> source, {
  required int total,
  void Function(int sent, int total)? onProgress,
  bool Function()? isCancelled,
}) async* {
  var sent = 0;
  await for (final chunk in source) {
    if (isCancelled != null && isCancelled()) {
      throw const LanUploadCancelledException();
    }
    sent += chunk.length;
    onProgress?.call(sent, total);
    yield chunk;
  }
}

class LanUploadCancelledException implements Exception {
  const LanUploadCancelledException();
}

/// 比 [File.openRead] 默认块更大，减少异步调度与系统调用次数，利于局域网吞吐。
Stream<List<int>> fileOpenReadChunked(
  File file,
  int start,
  int endExclusive, {
  int bufferBytes = 1024 * 1024,
}) {
  if (start < 0 || endExclusive < start) {
    throw ArgumentError('invalid range');
  }
  return _fileOpenReadChunkedImpl(file, start, endExclusive, bufferBytes);
}

Stream<List<int>> _fileOpenReadChunkedImpl(
  File file,
  int start,
  int endExclusive,
  int bufferBytes,
) async* {
  final raf = await file.open(mode: FileMode.read);
  try {
    await raf.setPosition(start);
    var pos = start;
    while (pos < endExclusive) {
      final n = (endExclusive - pos) < bufferBytes
          ? endExclusive - pos
          : bufferBytes;
      final data = await raf.read(n);
      if (data.isEmpty) break;
      yield data;
      pos += data.length;
    }
  } finally {
    await raf.close();
  }
}

/// 将 Dio [CancelToken] 转为 [httpClientUploadOctetStream] 可用的取消检查。
bool Function()? cancelTokenToChecker(CancelToken? token) {
  if (token == null) return null;
  return () => token.isCancelled;
}
